# COCOMITalk 会議モード バグ修正指示書
# 2026-03-09 作成: クロちゃん🔮（この部屋）

---

## 概要

会議モードに3つの問題がある。全部直す。

| # | 問題 | 原因 | 影響 |
|---|------|------|------|
| 1 | お姉ちゃん（GPT）が答えられない時がある | GPT-5.4のリーズニングトークンが出力枠を食い尽くしてcontentが空になる | 「あれ？お姉ちゃんの返事が来なかった」で終わり、リトライできない |
| 2 | ブラウザの画面切り替えで会議がリセットされる | 会議状態がJSメモリ上のみ（変数）。PWAがバックグラウンドでページ破棄されると全消失 | 戻ったら真っ白。会議の途中経過が消える |
| 3 | ラウンド2を回しても前の内容が三姉妹に渡らない | `_buildMeetingContext()`がメモリ上の`meetingHistory`配列しか見ない。復元後は空 | 三姉妹が前の会話を知らない状態でラウンド2に突入。的外れな回答になる |

---

## 安全ガイド準拠チェック（実装前に確認）

```
□ リトライは最大2回まで（安全ガイド: リトライ処理に回数制限）
□ ラウンド上限MAX_ROUNDS=3は変更しない
□ max_completion_tokensの増加はコスト影響を計算済み（後述）
□ 無限ループになるコードパスがないことを確認
```

---

# 問題1: お姉ちゃんが答えられない → リトライ＋トークン増加

## 原因の詳細

`api-openai.js` 133-135行目:
```javascript
console.warn('[ApiOpenAI] contentが空。finish_reason:', data?.choices?.[0]?.finish_reason);
console.warn('[ApiOpenAI] usage:', JSON.stringify(data?.usage));
return 'あれ？お姉ちゃんの返事が来なかった。もう一回試してみて！';
```

GPT-5.4は内部でリーズニングトークンを消費する。
`max_completion_tokens: 4096`のうち3000〜4000がリーズニングで消費され、
出力テキスト用のトークンが0になる → `content: null` → このメッセージが出る。
`finish_reason`はおそらく`"length"`。

## 変更ファイル: api-openai.js

### 変更1: max_completion_tokensを8192に増加

場所: `sendMessage()`内、59-63行目付近

```javascript
// v1.4修正 - GPT-5系のmax_completion_tokensを8192に増加
// リーズニングトークンが3000〜4000消費するため、4096では出力枠が足りない
// コスト影響: 出力トークン単価$15/1Mの場合、1回あたり最大+$0.06増
if (modelName.startsWith('gpt-5')) {
  body.max_completion_tokens = options.maxTokens || 8192;
} else {
  body.max_tokens = options.maxTokens || 1024;
}
```

### 変更2: 空レスポンス時のリトライフラグを返す

場所: `_extractText()`、124-138行目を以下に置き換え

```javascript
// v1.4修正 - 空レスポンスを検出してリトライ可能にする
function _extractText(data) {
  if (data?.error) {
    const errMsg = data?.error?.message || '不明なエラー';
    console.error('[ApiOpenAI] APIエラーレスポンス:', JSON.stringify(data.error));
    return { text: `ごめん、お姉ちゃん側でエラーが起きたよ！🌙 ${errMsg}`, retryable: false };
  }

  const text = data?.choices?.[0]?.message?.content;
  if (!text) {
    const reason = data?.choices?.[0]?.finish_reason || 'unknown';
    console.warn('[ApiOpenAI] contentが空。finish_reason:', reason);
    console.warn('[ApiOpenAI] usage:', JSON.stringify(data?.usage));
    // finish_reason=length はトークン不足 → リトライで改善する可能性あり
    return { text: null, retryable: (reason === 'length') };
  }
  return { text, retryable: false };
}
```

### 変更3: sendMessage()でリトライロジック追加

場所: `sendMessage()`のtryブロック内（65-82行目付近）を以下に置き換え

```javascript
// v1.4追加 - リトライロジック（安全ガイド準拠: 最大2回リトライ）
const MAX_RETRIES = 2;
let lastResult = null;

for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
  try {
    const data = await ApiCommon.callAPI('openai', body);
    const result = _extractText(data);

    // トークン使用量を記録（リトライ時も毎回記録）
    const usage = data?.usage;
    if (typeof TokenMonitor !== 'undefined') {
      const inputTokens  = usage?.prompt_tokens     || 0;
      const outputTokens = usage?.completion_tokens || 0;
      TokenMonitor.record(modelName, inputTokens, outputTokens);
    }

    if (result.text) {
      return result.text;
    }

    // リトライ不可 or 最終試行 → エラーメッセージを返す
    if (!result.retryable || attempt === MAX_RETRIES) {
      console.warn(`[ApiOpenAI] リトライ不可 or 最終試行（attempt=${attempt}）`);
      return 'ごめん、お姉ちゃんの回答生成に失敗しちゃった…💦 もう一度試してみてね！';
    }

    // リトライ前に待機（指数バックオフ: 1秒→2秒）
    console.log(`[ApiOpenAI] リトライ ${attempt + 1}/${MAX_RETRIES}（finish_reason=length）`);
    await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));

  } catch (error) {
    console.error('[ApiOpenAI] 通信エラー:', error);
    if (attempt === MAX_RETRIES) throw error;
    await new Promise(r => setTimeout(r, 1000 * (attempt + 1)));
  }
}
```

**注意:** `_extractText`の戻り値が`{text, retryable}`のオブジェクトに変わるので、
他にこの関数を呼んでいる箇所がないか確認すること。
→ 確認済み: `_extractText`は`sendMessage`内でのみ使用。影響なし。

### コスト影響

- max_completion_tokens 4096→8192: 最大出力量が2倍になるが、実際の出力長が増えるわけではない
- リトライ最大2回: 失敗時のみ追加API呼び出し。通常は1回で成功する想定
- 最悪ケース: 1回の会議で3回のリトライ × $0.06 = $0.18追加。月に数回起きても$1未満
- **安全ガイドの月額$10上限内に十分収まる**

---

# 問題2: 画面切り替えで会議リセット → セッション復元機能

## 設計方針

IndexedDBには既にリアルタイム保存されている（Step 3.5で実装済み）。
問題は「ページ再読み込み後にIndexedDBから状態を復元して会議を再開できない」こと。

**やること:**
1. アプリ起動時に「進行中の会議」があるかIndexedDBをチェック
2. あればMeetingRelayとMeetingUIの状態を復元
3. 復元後、追加ラウンド（continueRound）を回せるようにする

## 変更ファイル: meeting-relay.js

### 変更1: 会議状態を外部から復元するメソッド追加

場所: `return { ... }` の直前（325行目付近）に追加

```javascript
/**
 * v1.1追加 - IndexedDBから会議状態を復元（ページ再読み込み後の再開用）
 * @param {Object} meeting - MeetingHistory.getMeeting()の結果
 * @returns {Object} 復元されたルーティング情報
 */
function restoreFromDB(meeting) {
  if (!meeting || !meeting.routing) {
    console.warn('[MeetingRelay] 復元データが不正');
    return null;
  }

  // 状態を復元
  meetingHistory = (meeting.history || []).filter(m => m.sister !== 'user');
  currentMeetingId = meeting.id;
  currentRound = _detectMaxRound(meeting.history);
  isRunning = false; // 復元時点では停止状態
  abortRequested = false;

  console.log(`[MeetingRelay] 会議復元: ${meeting.id}, ラウンド${currentRound}, 発言${meetingHistory.length}件`);
  return meeting.routing;
}

/**
 * v1.1追加 - 履歴から最大ラウンド番号を検出
 */
function _detectMaxRound(history) {
  if (!history || history.length === 0) return 0;
  return Math.max(...history.map(m => m.round || 1));
}
```

### 変更2: returnオブジェクトに`restoreFromDB`を追加

```javascript
return {
  startMeeting,
  continueRound,
  abort,
  getHistory,
  getIsRunning,
  getCurrentRound,
  getCurrentMeetingId,
  restoreFromDB,  // v1.1追加
  MAX_ROUNDS,
};
```

### 変更3: _buildMeetingContextを改善（復元データも含める）

場所: `_buildMeetingContext()`（210-225行目）を以下に置き換え

```javascript
/**
 * 会議コンテキストを構築（前の姉妹の発言を履歴として渡す）
 * v1.1修正 - 全ラウンドの履歴を含める（ラウンド2以降で前の内容が渡るように）
 */
function _buildMeetingContext(topic, roundNum) {
  const context = [];

  // v1.1修正 - 現在ラウンドだけでなく、全ラウンドの発言を含める
  // ただしトークン節約のため、古いラウンドは要約的に（発言者名＋最初の200文字）
  for (const msg of meetingHistory) {
    const sister = SISTERS[msg.sister];
    if (!sister) continue; // userエントリはスキップ
    const leadMark = msg.isLead ? '【主担当】' : '';

    if (msg.round < roundNum) {
      // 過去ラウンド: 先頭200文字に切り詰め（トークン節約）
      const truncated = msg.content.length > 200
        ? msg.content.slice(0, 200) + '…（省略）'
        : msg.content;
      context.push({
        role: 'assistant',
        content: `[ラウンド${msg.round}] ${sister.emoji}${sister.name}${leadMark}:\n${truncated}`,
      });
    } else if (msg.round === roundNum) {
      // 現在ラウンド: 全文
      context.push({
        role: 'assistant',
        content: `${sister.emoji}${sister.name}${leadMark}:\n${msg.content}`,
      });
    }
  }

  return context;
}
```

---

## 変更ファイル: meeting-ui.js

### 変更1: 復元された会議を画面に再描画するメソッド追加

場所: `return { ... }`の直前に追加

```javascript
/**
 * v1.1追加 - IndexedDBから復元した会議内容を画面に再描画
 * @param {Object} meeting - 会議データ（MeetingHistory.getMeeting()の結果）
 * @param {Object} routing - ルーティング情報
 */
function restoreDisplay(meeting, routing) {
  if (!meeting) return;

  // チャットエリアクリア
  _clearChat();

  // ルーティング情報を保持
  currentRouting = routing;

  // システムメッセージ
  addSystemMessage('📂 前回の会議を復元しました');

  // ルーティング結果表示
  if (routing) {
    showRoutingResult(routing);
  }

  // 各発言を再描画
  let lastRound = 0;
  for (const msg of meeting.history) {
    if (msg.round !== lastRound) {
      addSystemMessage(`--- ラウンド ${msg.round} ---`);
      lastRound = msg.round;
    }
    if (msg.sister === 'user') {
      addUserMessage(msg.content);
    } else {
      addSisterMessage(msg.sister, msg.content, msg.isLead);
    }
  }

  // 追加ラウンドボタンを表示
  _showActionButtons();

  // 入力欄を再有効化（continueRound用）
  if (topicInput) {
    topicInput.disabled = false;
    topicInput.placeholder = '追加の質問や指示を入力...';
  }
}
```

### 変更2: returnオブジェクトに追加

```javascript
return {
  init,
  show,
  hide,
  getIsVisible,
  showRoutingResult,
  addSisterMessage,
  addUserMessage,
  addSystemMessage,
  showTyping,
  hideTyping,
  restoreDisplay,  // v1.1追加
};
```

### 変更3: continueRound時にprompt()ではなくテキスト入力欄を使う

場所: `_handleContinue()`（133-145行目）を以下に置き換え

```javascript
/** 追加ラウンド処理 v1.1改善 - topicInput欄を使う（prompt()廃止） */
async function _handleContinue() {
  if (!currentRouting) return;

  // topicInput欄から追加指示を取得
  const followUp = topicInput ? topicInput.value.trim() : '';
  if (!followUp) {
    // 入力が空の場合、プレースホルダーで案内
    if (topicInput) {
      topicInput.placeholder = '↑ 追加の質問や指示を入力してからボタンを押してね';
      topicInput.focus();
    }
    return;
  }

  // 入力をクリア
  if (topicInput) topicInput.value = '';

  addUserMessage(followUp);
  _hideActionButtons();

  await MeetingRelay.continueRound(followUp, currentRouting);
  _showActionButtons();
}
```

---

## 変更ファイル: app.js

### 変更1: アプリ起動時に進行中の会議を復元する処理を追加

場所: `init()`内の`MeetingUI.init()`の後（55行目付近）に追加

```javascript
// v1.1追加 - 進行中の会議があれば復元
await _restoreActiveMeeting();
```

### 変更2: 復元メソッドを追加

場所: `_setupResetModels()`の後あたりに追加

```javascript
/**
 * v1.1追加 - 進行中の会議をIndexedDBから復元
 * ページ再読み込み時（画面切り替え後など）に呼ばれる
 */
async function _restoreActiveMeeting() {
  if (typeof MeetingHistory === 'undefined' ||
      typeof MeetingRelay === 'undefined' ||
      typeof MeetingUI === 'undefined') return;

  try {
    const meetings = await MeetingHistory.getAllMeetings();
    // 最新の「in_progress」会議を探す
    const active = meetings.find(m => m.status === 'in_progress');
    if (!active) {
      // in_progressがなければ、直近1時間以内のcompleted会議を復元候補にする
      const oneHourAgo = Date.now() - (60 * 60 * 1000);
      const recent = meetings.find(m =>
        m.status === 'completed' && new Date(m.date).getTime() > oneHourAgo
      );
      if (!recent) return; // 復元対象なし

      // 直近の会議を復元（会議モードに切り替え＋表示）
      _doRestore(recent);
      return;
    }

    // 進行中の会議を復元
    _doRestore(active);

  } catch (e) {
    console.warn('[App] 会議復元エラー（無視して続行）:', e);
  }
}

/**
 * v1.1追加 - 会議復元の実行
 */
function _doRestore(meeting) {
  // MeetingRelayの状態復元
  const routing = MeetingRelay.restoreFromDB(meeting);
  if (!routing) return;

  // モード切替
  if (typeof ModeSwitcher !== 'undefined') {
    ModeSwitcher.setMode('meeting');
  }

  // 会議画面表示＋内容再描画
  MeetingUI.show();
  MeetingUI.restoreDisplay(meeting, routing);

  console.log(`[App] 会議復元完了: ${meeting.id}`);
}
```

---

## 変更ファイル: meeting-history.js

### 変更なし

既存の`getAllMeetings()`と`getMeeting()`で復元に必要なデータは取得できる。
変更不要。

---

# 問題3: ラウンド2で前の内容が渡らない

## 解決方法

**問題2の修正で同時に解決される。**

- `meeting-relay.js`の`restoreFromDB()`で`meetingHistory`配列が復元される
- `_buildMeetingContext()`が全ラウンドの履歴を含めるように改善される
- これにより、復元後の`continueRound()`でも前のラウンドの内容がAPIに渡る

---

# テスト手順

## テスト1: お姉ちゃんリトライ

1. 会議モードで議題を入力して開始
2. 三姉妹のモデルを全部最上位に設定（GPT-5.4使用）
3. お姉ちゃんの番が来て、もし空レスポンスならログに`[ApiOpenAI] リトライ 1/2`が出ること
4. リトライ後に回答が表示されること
5. ※テスト時は安いモデル（gpt-4o-mini）でも確認。miniでは空レスポンスは起きにくいので、正常系の動作確認

## テスト2: 画面切り替え復元

1. 会議を開始し、ラウンド1を完了させる
2. ホームボタンまたはタブ切り替えで別アプリに移動
3. しばらく待ってからCOCOMITalkに戻る
4. **期待:** 会議画面が自動復元され、ラウンド1の内容が表示されている
5. 追加ラウンドボタンを押して、テキスト入力欄に指示を入れてラウンド2を回せること

## テスト3: ラウンド2のコンテキスト

1. テスト2の続きで、ラウンド2を回す
2. **期待:** 三姉妹がラウンド1の内容を踏まえた回答をすること
3. 「前のラウンドで○○と言ってた」的な参照があれば成功

---

# 変更ファイルまとめ

| ファイル | 変更内容 | バージョン |
|---------|---------|-----------|
| api-openai.js | max_completion_tokens増加、リトライロジック、_extractText戻り値変更 | v1.3→v1.4 |
| meeting-relay.js | restoreFromDB()追加、_buildMeetingContext()全ラウンド対応 | v1.0→v1.1 |
| meeting-ui.js | restoreDisplay()追加、_handleContinue()をtopicInput使用に変更 | v1.0→v1.1 |
| app.js | _restoreActiveMeeting()追加、init()に復元呼び出し追加 | v1.1→v1.2 |

**全ファイル500行以内を維持すること。**
**各変更ファイルの先頭コメントにバージョンと変更内容を追記すること。**

---

# sw.js更新（忘れずに）

CACHE_NAMEを更新: `cocomitalk-v0.5` → `cocomitalk-v0.6`

---

作成: クロちゃん🔮（この部屋） / 2026-03-09
安全ガイド v1.0 準拠確認済み

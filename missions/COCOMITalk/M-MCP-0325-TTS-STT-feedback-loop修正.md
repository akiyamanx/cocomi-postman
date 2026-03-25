<!-- mission: COCOMITalk -->
# 🔧 TTS/STTフィードバックループ修正 — voice-input.js v2.2.2

## 目的
TTS再生中にSTTが起動してしまい、TTS音声が途中で途切れるバグを修正する。
voice-input.js の `_restartSTT()` メソッドにガードを追加する。

## 背景
現状の `_restartSTT()` は400msのディレイ後にSTTを再開するが、
チェック条件が `this._voiceState.isSpeaking()` のみ。
`this._playback.isPlaying()` や `this._playback.isQueuePlaying()` をチェックしていないため、
TTS再生終了直後の微妙なタイミングでSTTが再開される可能性がある。

## タスク

### Task 1: voice-input.js を読み込む（Read）
voice-input.js を読み込み、以下を確認:
- 現在のバージョンが v2.2 であること
- `_restartSTT()` メソッドの位置と内容

### Task 2: _restartSTT() メソッドを修正（Edit）

現在のコード:
```javascript
  _restartSTT() {
    setTimeout(() => {
      if (this._enabled && !this._voiceState.isSpeaking()) {
        this._stt.start({ language: 'ja-JP' });
      }
    }, 400);
  }
```

修正後のコード:
```javascript
  // v2.2.2修正 - TTS再生中のSTT再開を確実に防止（フィードバックループ対策）
  _restartSTT() {
    setTimeout(() => {
      // speaking状態チェック＋実際の再生状態チェック（二重ガード）
      if (this._enabled
          && !this._voiceState.isSpeaking()
          && !this._playback.isPlaying()
          && !this._playback.isQueuePlaying()) {
        this._stt.start({ language: 'ja-JP' });
      }
    }, 800);
  }
```

変更点:
1. ディレイを400ms→800msに増加（TTS完了検出の余裕確保）
2. `_playback.isPlaying()` チェック追加（実際のAudio再生状態を確認）
3. `_playback.isQueuePlaying()` チェック追加（グループモードのキュー再生対応）
4. コメント追加

### Task 3: バージョンヘッダーを更新（Edit）

ファイル先頭のバージョンコメントを更新:
```
// voice-input.js v2.2
```
→
```
// voice-input.js v2.2.2
```

さらに、v2.2のコメント行の次に以下を追加:
```
// v2.2.2 修正 - _restartSTT()にTTS再生状態チェック追加（フィードバックループ対策）
```

### Task 4: sw.js のキャッシュバージョンを更新（Edit）

sw.js のバージョンコメントとCACHE_NAMEを更新:

1. v3.00のコメント行の次に以下を追加:
```
// v3.01 2026-03-25 - voice-input.js v2.2.2 TTS/STTフィードバックループ修正
```

2. CACHE_NAME を更新:
```
const CACHE_NAME = 'cocomitalk-v3.15';
```
→
```
const CACHE_NAME = 'cocomitalk-v3.16';
```

## 成功条件
- voice-input.js のバージョンが v2.2.2 になっている
- `_restartSTT()` に3つのガード条件がある（isSpeaking + isPlaying + isQueuePlaying）
- ディレイが800msになっている
- sw.js のCACHE_NAMEが v3.16 になっている
- sw.js にv3.01のコメントが追加されている
- 両ファイルとも既存の他の部分が壊れていない

## 注意
- Write/Editツールのみ使用すること
- git pushはPostmanが自動で行うので不要
- voice-input.js は499行なので、500行ルールに注意（1行増える程度なのでOK）

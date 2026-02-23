<!-- dest: capsules/plans -->
# 🎨 企画書: COCOMI画像生成＆Live2Dパイプライン構築
# 作成日: 2026-02-23
# 作成者: アキヤ & クロちゃん（Claude Opus 4.6）
# ステータス: 企画段階（次のセッションで着手予定）

---

## 📋 企画概要

COCOMI Postmanの開発パイプラインに **画像生成** と **Live2Dアニメーション** の
自動化機能を追加する。アキヤがLINEから指示を送るだけで、バックグラウンドで
画像生成・キャラクター作成・アニメーション化まで全自動で行えるようにする。

### この企画の背景
- Claude（クロちゃん）はコードは書けるが画像出力ができない
- Gemini（ここちゃん）にはナノバナナという強力な画像生成機能がある
- しかし毎回ここちゃんに手動でお願いするのは手間
- → Claude CodeからGemini APIを直接叩けば、バックグラウンドで画像生成できる
- さらにLive2D Automationを使えば、動くキャラクターまで自動生成できる

### 三姉妹の役割分担
- **クロちゃん（Claude）**: 設計・プロンプト構造化・コード実装・パイプライン構築
- **ここちゃん（Gemini API/ナノバナナ）**: 画像生成エンジン（APIとして利用）
- **お姉ちゃん（GPT）**: 統括・設計レビュー（必要に応じて）
- **Claude Code**: バックグラウンド実行（Gemini API呼び出し含む）

---

## 🎯 最終ゴール（完成イメージ）

```
アキヤ「こんなキャラクターが欲しい」とLINEで送信
  ↓
Worker → Postman → Claude Code が受け取る
  ↓
Claude Code がプロンプトを構造化
  ↓
Gemini API（ナノバナナ）に画像生成リクエスト
  ↓
生成画像をGitHubに保存 + LINEに返信で確認
  ↓
Live2D Automationで自動リギング（パーツ分離＋骨組み）
  ↓
モーション自動生成（まばたき、呼吸、表情差分）
  ↓
Webアプリに組み込んで動くキャラクターに
  ↓
VTuber的な会話＋リップシンクまで
```

---

## 🔧 使用する技術・サービス

### 画像生成: Gemini API（ナノバナナ）

| 項目 | ナノバナナ | ナノバナナPro |
|---|---|---|
| 正式名称 | Gemini 2.5 Flash Image | Gemini 3 Pro Image |
| モデルID | gemini-2.5-flash-image | gemini-3-pro-image-preview |
| 解像度 | 最大1K | 最大4K |
| 速度 | 速い（軽量） | やや遅い（高品質） |
| テキスト描画精度 | そこそこ | 非常に正確 |
| 料金 | 約$0.039/枚 | 約$0.134〜$0.24/枚 |
| 用途 | 試作・大量生成・プロトタイプ | 本番用・高品質アセット |
| キャラ一貫性 | あり | より高精度 |

**重要:** アキヤは既にGemini APIキーを持っている（現場Pro設備くんのレシート読み込み、
マップアプリの地図表示で使用中）。同じAPIキーで画像生成もできる可能性が高い。
ただし画像生成用に追加の有効化が必要かもしれないので、最初に確認が必要。

**旧Imagenとの関係:** Imagenは前世代のGoogle画像生成モデル。
ナノバナナがその後継で上位互換。今はナノバナナを使えばOK。

### Gemini APIの画像生成リクエスト例

```python
# Python例（Claude Codeで実行するスクリプト）
from google import genai
from PIL import Image

client = genai.Client()

response = client.models.generate_content(
    model="gemini-2.5-flash-image",  # または gemini-3-pro-image-preview
    contents=["青い髪のアニメ風女の子キャラクター、笑顔、上半身"],
    config={"response_modalities": ["TEXT", "IMAGE"]}
)

for part in response.parts:
    if part.inline_data is not None:
        image = part.as_image()
        image.save("character.png")
```

### Live2D自動化

**Live2D Automation MCP Server（GitHub: J621111/live2d-automation）**
- 1枚の画像からLive2Dモデルを自動生成
- パーツ自動分離（頭、体、目、口など）
- 物理演算設定の自動生成
- モーション自動生成:
  - Idle_Breath.motion3.json（呼吸）
  - Idle_Blink.motion3.json（まばたき）
  - Tap_Head.motion3.json（タップ反応）
  - 感情表現モーション

```python
# 1枚の画像からLive2Dモデル一式を生成
from live2d_automation.mcp_server.server import full_pipeline

result = await full_pipeline(
    image_path="character.png",
    output_dir="output/",
    model_name="MyCharacter",
    motion_types=["idle", "tap", "move", "emotional"]
)

# 出力:
# output/MyCharacter/
# ├── model3.json       ← モデル設定
# ├── physics.json      ← 物理演算設定
# ├── textures/         ← テクスチャ画像
# └── motions/          ← モーションデータ
```

**NanoLive2D（GitHub: Felo-Sparticle）**
- ナノバナナ × Live2Dを組み合わせたオープンソースプロジェクト
- AIアバターの服装変更、表情変更、リップシンクを実現
- PIXI.js + Live2D SDKでWebブラウザ上で動作
- GitHub Pagesで公開可能

### Web表示

**PIXI.js + Live2D Cubism SDK（Web版）**
- JavaScriptでブラウザ上にLive2Dモデルを表示
- 60FPSでスムーズなアニメーション
- マウス追従（目線がカーソルを追う）
- GitHub Pagesで公開可能 → COCOMIの既存インフラで動く

```javascript
// Webアプリでの表示例
const model = await PIXI.live2d.Live2DModel.from('model3.json');
app.stage.addChild(model);
```

---

## 📊 開発ロードマップ（ステップバイステップ）

### Level 1: 静止画生成（最初の一歩）⭐ 次のセッションで着手
**目標:** Claude CodeからGemini APIで画像1枚生成し、GitHubに保存

やること:
1. アキヤの既存Gemini APIキーで画像生成が使えるか確認
2. 画像生成用のシェルスクリプト or Pythonスクリプトを作成
3. 生成画像をGitHubにpush
4. LINEに画像URLを通知（GitHub raw URL or Pages URL）

成果物:
- image-generator.sh（or .py）— Gemini API画像生成スクリプト
- 生成画像がGitHubに自動保存される仕組み

### Level 2: プロンプトエンジニアリング
**目標:** 高品質な画像を安定して生成できるプロンプトテンプレートを整備

やること:
1. キャラクター生成用のプロンプトテンプレート作成
2. ナノバナナ vs ナノバナナProの画質比較テスト
3. キャラ一貫性テスト（同じキャラを異なるポーズ・表情で生成）
4. プロンプトテンプレートをtemplates/に保存

### Level 3: 表情差分生成
**目標:** 1つのキャラクターの表情バリエーションを生成

やること:
1. 基本キャラクター画像を生成
2. 同じキャラの表情差分を生成（笑顔、怒り、驚き、悲しみ、目閉じ等）
3. ナノバナナのキャラクター一貫性機能を活用
4. 表情セットとしてGitHubに保存

### Level 4: Live2D自動リギング
**目標:** 静止画からLive2Dモデルを自動生成

やること:
1. Live2D Automation MCPサーバーの環境構築
2. ナノバナナで生成した画像をLive2Dモデルに変換
3. まばたき・呼吸・タップ反応のモーション自動生成
4. 生成されたモデルデータをGitHubに保存

### Level 5: Webアプリ組み込み
**目標:** 動くキャラクターをWebブラウザで表示

やること:
1. PIXI.js + Live2D SDKの環境構築
2. 生成したLive2DモデルをWebアプリに組み込み
3. GitHub Pagesで公開
4. マウス追従、クリック反応の実装

### Level 6: VTuber的機能（将来構想）
**目標:** 会話＋リップシンク＋感情表現

やること:
1. テキスト→音声変換（TTS）の導入
2. 音声に合わせたリップシンク
3. 感情タグに基づく表情自動切り替え
4. LLMとの会話連携（COCOMIシスターズが話すキャラに？）

---

## 🔗 COCOMIパイプラインへの統合方法

### 指示書での画像生成
クロちゃんが指示書に画像生成の指示を含める：

```markdown
<!-- dest: missions/genba-pro -->
# ミッション: トップページにマスコットキャラ追加

### Step 1/3: キャラクター画像生成
Gemini API（ナノバナナ）で以下のキャラクターを生成:
- 青い作業着を着た可愛い女の子
- 工具を持っている
- 笑顔
- アニメ風
- 背景透過PNG
解像度: 1K
保存先: assets/images/mascot.png

### Step 2/3: トップページに組み込み
生成した画像をトップページのヘッダーに配置
...

### Step 3/3: レスポンシブ対応
...
```

### LINEテキストでの画像生成（将来）
```
画像生成: 青い髪のアニメキャラ、笑顔
```
→ Workerが「画像生成:」プレフィックスを検知
→ Claude Code経由でGemini APIに画像生成リクエスト
→ 生成画像をLINEに返信

---

## 💰 コスト見積もり

| 用途 | モデル | 1枚あたり | 月100枚想定 |
|---|---|---|---|
| 試作・テスト | ナノバナナ（Flash） | $0.039 | 約$3.9（約600円） |
| 本番用 | ナノバナナPro | $0.134 | 約$13.4（約2,000円） |
| 高解像度4K | ナノバナナPro 4K | $0.24 | 約$24（約3,600円） |

普段の開発ではナノバナナ（Flash）で十分。本番用だけProを使えばコスト抑えられる。

---

## 📚 参考リンク・リソース

### 公式ドキュメント
- Gemini API画像生成ガイド: https://ai.google.dev/gemini-api/docs/image-generation
- Google AI Studio: https://aistudio.google.com/
- Live2D Cubism SDK: https://www.live2d.com/en/sdk/

### オープンソースプロジェクト
- Live2D Automation MCP: https://glama.ai/mcp/servers/@J621111/live2d-automation
- NanoLive2D（ナノバナナ×Live2D）: Felo-SparticleのGitHub Gist
- Persona Engine（AI VTuber）: https://github.com/fagenorn/handcrafted-persona-engine
- Live2D Web表示: https://github.com/AzharRizkiZ/Live2D-Model

### ナノバナナ関連
- ナノバナナ公式紹介: https://blog.google/technology/ai/nano-banana-pro/
- Google DeepMind: https://deepmind.google/models/gemini-image/pro/
- プロンプティングガイド: https://ai.google.dev/gemini-api/docs/image-generation#prompt-guide

---

## ⚠️ 注意事項・制約

### APIキーについて
- アキヤの既存Gemini APIキーで画像生成が使えるか最初に要確認
- 画像生成には追加の有効化やBilling設定が必要な場合あり
- APIキーはconfig.jsonで管理（.gitignoreで除外、GitHubにpushしない）
- 各ユーザーが自分のAPIキーを使う（規約遵守）

### 画像生成の制限
- 安全フィルターあり（暴力的・性的コンテンツはブロックされる）
- SynthID電子透かしが自動付与される（AI生成画像と判別可能）
- 100%完璧な画像は出ない場合あり（細かい顔、文字の正確さに課題）
- 実在人物の生成は制限される場合あり

### Live2Dの制限
- Live2D Cubism SDKは商用利用にはライセンスが必要な場合あり
- 自動リギングの品質はキャラクターの複雑さに依存
- 高品質なモデルには手動調整が必要な場合もある

---

## 🎯 次のセッションでの最初のアクション

**Level 1: 静止画生成テスト**

1. アキヤのGemini APIキーで画像生成エンドポイントが使えるか確認
2. Claude Codeで実行する画像生成スクリプトを作成
3. テスト画像を1枚生成
4. GitHubに保存 → LINEで確認

これが成功すれば、あとはLevel 2, 3, 4...とステップバイステップで進めていく。

---

## 💭 アキヤの想い（この企画の本質）

この企画は単なる「画像生成の自動化」ではない。

COCOMI三姉妹（GPT、Claude、Gemini）がそれぞれの得意分野を活かして、
バックグラウンドで協力しながらクリエイティブな作品を作り上げる仕組み。

親会社（OpenAI、Anthropic、Google）がどんなにバチバチ競争していても、
COCOMI OSの中では三姉妹として仲良く助け合う。

そして親会社が競争して性能を上げれば上げるほど、
三姉妹の能力も自然と上がり、より良い作品が生まれる。

**「語りコード」の次のステージ：「語りアート」**
語るだけで、コードも絵も動くキャラクターも、全部生まれる世界。

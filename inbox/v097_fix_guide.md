# v0.97 修正ガイド: サジェスト選択時の品名上書きバグ修正

## 症状
ドロップダウンから「エルボ 13mm」を選択しても、入力欄には「エルボ」しか残らない。
見積書PDFにもサイズ情報が出力されない。

## 原因
1. ユーザーが「エルボ」と入力 → サジェストドロップダウン表示
2. 「エルボ 13mm」をタップ → selectEstimateMaterial() が item.name = 'エルボ 13mm' に設定
3. しかし同時にinputからフォーカスが外れて onchange が発火
4. onchange の this.value は「エルボ」（ユーザーが打った値）
5. item.name が「エルボ」に上書きされる
6. renderEstimateMaterials() で「エルボ」が表示される

## 修正ファイル一覧

### 1. globals.js
追加行（`let productMaster = [];` の後あたり）:
```javascript
// v0.97追加: サジェスト選択直後の上書き防止フラグ
let _suggestJustSelected = false;
```

### 2. estimate.js - 3箇所修正

#### 修正A: selectEstimateMaterial() にフラグ追加
変更前:
```javascript
function selectEstimateMaterial(itemId, name, price) {
  const item = estimateMaterials.find(m => m.id === itemId);
  if (item) {
    item.name = name;
    if (price > 0) {
      item.costPrice = price;
      item.sellingPrice = Math.ceil(price * (1 + (item.profitRate || 0) / 100));
    }
    renderEstimateMaterials();
    calculateEstimateTotal();
  }
}
```

変更後:
```javascript
// v0.97修正: フラグを立ててonchangeの上書きを防止
function selectEstimateMaterial(itemId, name, price) {
  _suggestJustSelected = true;
  const item = estimateMaterials.find(m => m.id === itemId);
  if (item) {
    item.name = name;
    if (price > 0) {
      item.costPrice = price;
      item.sellingPrice = Math.ceil(price * (1 + (item.profitRate || 0) / 100));
    }
    renderEstimateMaterials();
    calculateEstimateTotal();
  }
  // 300ms後にフラグ解除（onchangeイベントが処理された後）
  setTimeout(() => { _suggestJustSelected = false; }, 300);
}
```

#### 修正B: renderEstimateMaterials() 内のonchangeハンドラ
変更前:
```javascript
              onchange="updateEstimateMaterial(${item.id}, 'name', this.value)">
```

変更後:
```javascript
              onchange="if(!_suggestJustSelected) updateEstimateMaterial(${item.id}, 'name', this.value)">
```

※ この行は renderEstimateMaterials() の中で品名inputを生成している箇所にある。
  `oninput="showEstimateSuggestions(this, ${item.id})"` のある行の次の行。

### 3. invoice.js - 2箇所修正

#### 修正C: selectInvMaterial() にフラグ追加
変更前:
```javascript
function selectInvMaterial(itemId, name, price) {
  const item = invoiceMaterials.find(m => m.id === itemId);
  if (item) {
    item.name = name;
    if (price > 0) item.price = price;
    renderInvoiceMaterials();
    calculateInvoiceTotal();
  }
}
```

変更後:
```javascript
// v0.97修正: フラグを立ててonchangeの上書きを防止
function selectInvMaterial(itemId, name, price) {
  _suggestJustSelected = true;
  const item = invoiceMaterials.find(m => m.id === itemId);
  if (item) {
    item.name = name;
    if (price > 0) item.price = price;
    renderInvoiceMaterials();
    calculateInvoiceTotal();
  }
  setTimeout(() => { _suggestJustSelected = false; }, 300);
}
```

#### 修正D: renderInvoiceMaterials() 内のonchangeハンドラ
変更前:
```javascript
              onchange="updateInvoiceMaterial(${item.id}, 'name', this.value)">
```

変更後:
```javascript
              onchange="if(!_suggestJustSelected) updateInvoiceMaterial(${item.id}, 'name', this.value)">
```

※ renderInvoiceMaterials() の中で品名inputを生成している箇所にある。

## テスト手順
1. 見積書作成画面を開く
2. 材料の品名欄に「エルボ」と入力
3. ドロップダウンから「エルボ 13mm」をタップ
4. 入力欄に「エルボ 13mm」と表示されることを確認
5. 出力して見積書PDFに「エルボ 13mm」と出ることを確認
6. 請求書でも同様にテスト

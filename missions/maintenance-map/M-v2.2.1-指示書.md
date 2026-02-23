<!-- dest: missions/maintenance-map -->
# maintenance-map-ap v2.2.1 修正指示書
# ポップアップから訪問順設定 + CSV項目追加 + ルートタブ確認専用化

## 概要
v2.2で実装された訪問順設定のUIを改善する。
ルートタブのドラッグ&ドロップ方式から、地図ピンのポップアップ内ドロップダウン方式に変更。
またCSV/Excel読み込み時に営業所・型式・U管理NO・交換フィルターの4項目を追加取得し、
ポップアップの詳細情報に表示する。

## 重要ルール
- 1ファイル500行以内厳守
- コメントは日本語で書く
- 各ファイル先頭にバージョン番号を記載する（v2.2.1）
- 既存コードの動作を破壊しない
- 変更したファイルにはバージョンコメントを入れる（例：// v2.2.1変更）

## 変更対象ファイル
1. csv-handler.js — detectColumns()に4項目追加、processRows()で保存
2. map-core.js — showInfoWindow()に4項目表示＋訪問順ドロップダウン追加
3. route-manager.js — 🔢ボタン削除（ルートタブは確認専用に）
4. route-order.js — startEdit/renderSortableListモーダル削除、ポップアップ用の訪問順更新関数に差し替え
5. sw.js — CACHE_NAME更新

---

## 1. csv-handler.js の変更

### 1-1. detectColumns() に4項目の検出ルールを追加

現在のdetectColumns関数のmapオブジェクト初期化部分を以下に変更:

```javascript
const map = {
    company: -1,
    address: -1,
    phone: -1,
    contact: -1,
    note: -1,
    managementNo: -1,
    // v2.2.1追加 - 4項目
    branch: -1,        // 営業所
    model: -1,         // 型式
    filter: -1         // 交換フィルター
};
```

detectColumnsのforループ内に、既存のelse ifチェーンに以下を追加（`managementNo`の判定の後に）:

```javascript
// v2.2.1追加 - 営業所
if (map.branch === -1 && (h.includes('営業所') || h.includes('branch') || h.includes('支店'))) {
    map.branch = i;
}
// v2.2.1追加 - 型式（「型式」「型番」「タイプ」にマッチ、ただし「交換機種」は除外）
if (map.model === -1 && (h.includes('型式') || h.includes('型番') || h.includes('タイプ')) && !h.includes('交換')) {
    map.model = i;
}
// v2.2.1追加 - 交換フィルター
if (map.filter === -1 && (h.includes('フィルター') || h.includes('filter') || h.includes('交換フィルター'))) {
    map.filter = i;
}
```

**重要:** 既存の`managementNo`の検出ルールも改善する。現在は`h.includes('管理') || h.includes('no')`だが、
「U管理NO」にマッチするよう以下に変更:

```javascript
} else if (h.includes('管理') || h.includes('管理no') || h.includes('u管理')) {
    if (map.managementNo === -1) map.managementNo = i;
}
```

### 1-2. processRows() の顧客オブジェクト構築に3項目を追加

現在のcustomerオブジェクトに以下を追加（`managementNo`の行の後に）:

```javascript
const customer = {
    company: company,
    address: address,
    phone: colMap.phone >= 0 ? String(row[colMap.phone] || '').trim() : '',
    contact: colMap.contact >= 0 ? String(row[colMap.contact] || '').trim() : '',
    note: colMap.note >= 0 ? String(row[colMap.note] || '').trim() : '',
    managementNo: colMap.managementNo >= 0 ? String(row[colMap.managementNo] || '').trim() : '',
    // v2.2.1追加 - 3項目
    branch: colMap.branch >= 0 ? String(row[colMap.branch] || '').trim() : '',
    model: colMap.model >= 0 ? String(row[colMap.model] || '').trim() : '',
    filter: colMap.filter >= 0 ? String(row[colMap.filter] || '').trim() : ''
};
```

**注意:** addressのcolMapは都道府県(F列)+住所(G列)を結合するのが望ましい。
現在は住所列のみ取得しているが、Excelでは都道府県と住所が分かれている。
detectColumnsに都道府県の検出も追加し、processRowsでaddress構築時に結合する:

detectColumnsのmapに追加:
```javascript
prefecture: -1     // 都道府県
```

forループに追加:
```javascript
if (map.prefecture === -1 && (h.includes('都道府県') || h.includes('prefecture') || h.includes('県'))) {
    map.prefecture = i;
}
```

processRowsのaddress構築を変更:
```javascript
// v2.2.1変更 - 都道府県+住所を結合
let address = colMap.address >= 0 ? String(row[colMap.address] || '').trim() : '';
if (colMap.prefecture >= 0) {
    const pref = String(row[colMap.prefecture] || '').trim();
    if (pref && !address.startsWith(pref)) {
        address = pref + address;
    }
}
```

---

## 2. map-core.js の変更

### 2-1. showInfoWindow() に4項目の表示を追加

現在の`showInfoWindow`関数内、`managementNo`の表示の後に以下を追加:

```javascript
// v2.2.1追加 - 営業所
if (customer.branch) html += `<p>🏢 営業所: ${customer.branch}</p>`;
// v2.2.1追加 - 型式
if (customer.model) html += `<p>💧 型式: ${customer.model}</p>`;
// v2.2.1追加 - U管理NO（managementNoが既にあるので、これは表示済み）
// v2.2.1追加 - 交換フィルター
if (customer.filter) html += `<p>🔧 フィルター: ${customer.filter}</p>`;
```

### 2-2. showInfoWindow() に訪問順ドロップダウンを追加

ポップアップの編集・電話ボタンの**前**（`info-actions` divの前）に、
顧客がルートに割り当てられている場合のみ訪問順ドロップダウンを表示する。

以下のコードを `html += '<div class="info-actions">';` の直前に追加:

```javascript
// v2.2.1追加 - 訪問順ドロップダウン（ルート割当済みの場合のみ）
if (customer.routeId) {
    const routes = DataStorage.getRoutes();
    const currentRoute = routes.find(r => r.id === customer.routeId);
    const routeMembers = DataStorage.getCustomers().filter(c => c.routeId === customer.routeId);
    const currentOrder = currentRoute && currentRoute.order ? currentRoute.order : [];
    const currentIdx = currentOrder.indexOf(customer.id);
    // 現在の訪問順番号（orderに含まれていなければ「未設定」）
    const currentNum = currentIdx >= 0 ? currentIdx + 1 : -1;

    html += `<div class="info-visit-order">`;
    html += `<span>🔢 訪問順:</span>`;
    html += `<select class="visit-order-select" onchange="RouteOrder.setVisitOrder('${customer.routeId}','${customer.id}',this.value)">`;
    html += `<option value="-1" ${currentNum === -1 ? 'selected' : ''}>未設定</option>`;
    for (let i = 1; i <= routeMembers.length; i++) {
        html += `<option value="${i}" ${currentNum === i ? 'selected' : ''}>${i}番</option>`;
    }
    html += `</select>`;
    html += `</div>`;
}
```

### 2-3. showInfoWindow()内の既存model表示の重複を防ぐ

現在のコードに `if (customer.model) html += '<p>💧 ${customer.model}</p>';` が既にある。
v2.2.1で型式表示を追加するので、既存のmodel行は削除するか、
ラベルを変えて区別する（既存は「機種名」、新規は「型式」として両方残す場合）。

**確認:** 既存のcustomer.modelは v1.0互換の「機種名」フィールド。
新しいcustomer.modelもExcelの「型式」列。名前が被るので、
Excelの型式列は `model` ではなく `equipType` に変更する。

→ csv-handler.jsのフィールド名を `model` → `equipType` に修正:
```javascript
equipType: colMap.model >= 0 ? String(row[colMap.model] || '').trim() : '',
```

→ map-core.jsの表示も:
```javascript
if (customer.equipType) html += `<p>⚙️ 型式: ${customer.equipType}</p>`;
```

---

## 3. route-manager.js の変更

### 3-1. 🔢ボタンを削除してルートタブを確認専用にする

updateRoutePanel()内の以下の部分を削除:

```javascript
// この部分を削除
if (members.length >= 2) {
    html += `<button class="route-order-btn" onclick="event.stopPropagation();RouteOrder.startEdit('${route.id}')">🔢</button>`;
}
```

**注意:** 📏距離計算ボタンはそのまま残す。

---

## 4. route-order.js の変更

### 4-1. ドラッグ&ドロップ関連のコードを削除し、ポップアップ用の関数に差し替え

route-order.jsの内容を以下の軽量版に**全面置き換え**する:

```javascript
// ============================================
// メンテナンスマップ v2.2.1 - route-order.js
// ルート訪問順管理（ポップアップからの設定）
// v2.2新規作成 → v2.2.1全面改修: ドラッグ&ドロップ廃止、ポップアップ内ドロップダウン方式に変更
// ============================================

const RouteOrder = (() => {

    // v2.2.1 - ポップアップのドロップダウンから訪問順を設定する
    // routeId: ルートID, customerId: 顧客ID, position: 選択された番号(1始まり、-1は未設定)
    function setVisitOrder(routeId, customerId, position) {
        position = parseInt(position);
        const routes = DataStorage.getRoutes();
        const route = routes.find(r => r.id === routeId);
        if (!route) return;

        // v2.2.1 - 現在のorder配列を取得（なければ空）
        let order = route.order ? [...route.order] : [];
        const customers = DataStorage.getCustomers().filter(c => c.routeId === routeId);

        // v2.2.1 - まず対象の顧客をorderから除去
        order = order.filter(id => id !== customerId);

        if (position === -1) {
            // v2.2.1 - 「未設定」が選ばれた場合はorderから除去したまま
            DataStorage.updateRouteOrder(routeId, order);
        } else {
            // v2.2.1 - 指定位置に挿入（0始まりに変換）
            const insertIdx = Math.min(position - 1, order.length);
            order.splice(insertIdx, 0, customerId);
            DataStorage.updateRouteOrder(routeId, order);
        }

        // v2.2.1 - ルートタブの表示を更新
        RouteManager.updateRoutePanel();

        // v2.2.1 - ポップアップを更新（変更を即反映）
        const marker = MapCore.getMarkers().find(m => m.customData && m.customData.id === customerId);
        if (marker) {
            const updatedCustomer = DataStorage.getCustomers().find(c => c.id === customerId);
            if (updatedCustomer) {
                // 少し遅延させてInfoWindowを再描画
                setTimeout(() => {
                    MapCore.focusMarker(customerId);
                }, 100);
            }
        }
    }

    // v2.2.1 - 区間道路種別エディタを表示する（距離計算ボタンから呼ばれる）
    function showSegmentEditor(routeId, order) {
        if (!routeId || !order || order.length < 2) return;

        const customers = DataStorage.getCustomers();
        const segments = DataStorage.getSegments();
        const routeSegments = segments[routeId] || {};

        let html = '<div class="ro-modal-overlay" id="segmentEditorModal">';
        html += '<div class="ro-modal">';
        html += '<h3>🛣️ 区間の道路種別</h3>';
        html += '<p class="ro-hint">各区間で「高速」「下道」を選択</p>';
        html += '<div class="seg-list">';

        for (let i = 0; i < order.length - 1; i++) {
            const fromC = customers.find(c => c.id === order[i]);
            const toC = customers.find(c => c.id === order[i + 1]);
            if (!fromC || !toC) continue;

            const segKey = `${order[i]}_${order[i + 1]}`;
            const currentType = routeSegments[segKey] || 'general';

            const fromName = (fromC.company || '不明').substring(0, 10);
            const toName = (toC.company || '不明').substring(0, 10);

            html += `<div class="seg-item">`;
            html += `<div class="seg-label">${i + 1}. ${fromName} → ${toName}</div>`;
            html += `<div class="seg-toggle">`;
            html += `<button class="seg-btn ${currentType === 'general' ? 'seg-btn-active' : ''}" `;
            html += `onclick="RouteOrder.setSegType('${segKey}','general',this)">🚗 下道</button>`;
            html += `<button class="seg-btn ${currentType === 'highway' ? 'seg-btn-active' : ''}" `;
            html += `onclick="RouteOrder.setSegType('${segKey}','highway',this)">🛣️ 高速</button>`;
            html += `</div></div>`;
        }

        html += '</div>';
        html += '<div class="ro-actions">';
        html += '<button class="ro-btn ro-btn-cancel" onclick="RouteOrder.closeSegmentEditor()">閉じる</button>';
        html += '<button class="ro-btn ro-btn-save" onclick="RouteOrder.saveSegments()">✅ 保存</button>';
        html += '</div>';
        html += '</div></div>';

        RouteOrder._segRouteId = routeId;
        RouteOrder._segData = { ...routeSegments };

        const existing = document.getElementById('segmentEditorModal');
        if (existing) existing.remove();
        document.body.insertAdjacentHTML('beforeend', html);
    }

    // v2.2.1 - 区間の道路種別を切り替える
    function setSegType(segKey, type, btn) {
        RouteOrder._segData[segKey] = type;
        const parent = btn.parentElement;
        parent.querySelectorAll('.seg-btn').forEach(b => b.classList.remove('seg-btn-active'));
        btn.classList.add('seg-btn-active');
    }

    // v2.2.1 - 区間データを保存する
    function saveSegments() {
        const routeId = RouteOrder._segRouteId;
        if (!routeId) return;
        const allSegments = DataStorage.getSegments();
        allSegments[routeId] = RouteOrder._segData;
        DataStorage.saveSegments(allSegments);
        closeSegmentEditor();
        alert('✅ 区間の道路種別を保存しました！');
    }

    // v2.2.1 - 区間エディタを閉じる
    function closeSegmentEditor() {
        const modal = document.getElementById('segmentEditorModal');
        if (modal) modal.remove();
    }

    // v2.2.1 - 公開API
    return {
        setVisitOrder,
        showSegmentEditor, setSegType, saveSegments, closeSegmentEditor
    };
})();
```

---

## 5. route-order-styles.css の変更

v2.2.1ではドラッグ&ドロップ用のスタイル（.ro-item, .ro-grip, .ro-dragging等）は不要になる。
ただし区間エディタ用スタイル（.seg-list, .seg-item, .seg-btn等）は残す。

以下のスタイルを**追加**する（ポップアップの訪問順ドロップダウン用）:

```css
/* v2.2.1追加 - ポップアップ内訪問順ドロップダウン */
.info-visit-order {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 8px 0;
    padding: 6px 8px;
    background: #f0f9ff;
    border-radius: 6px;
    font-size: 13px;
}

.visit-order-select {
    padding: 4px 8px;
    border: 1px solid #93c5fd;
    border-radius: 4px;
    font-size: 13px;
    background: white;
    color: #1e40af;
    font-weight: 600;
}
```

ドラッグ&ドロップ用の以下のスタイルは削除してよい:
- .ro-item の dragging 関連
- .ro-grip
- .ro-dragging
- .ro-num（不要になるため）

---

## 6. sw.js の変更

CACHE_NAMEを更新:
```javascript
const CACHE_NAME = 'maintenance-map-v2.2.1';
```

---

## 確認事項
- 変更後、CSVまたはExcelファイルを読み込んで営業所・型式・U管理NO・交換フィルターが保存されること
- 地図のピンをタップしてポップアップに4項目が表示されること
- ポップアップ内のドロップダウンで訪問順を変更できること
- ルートタブに訪問順が反映されて表示されること（変更はできない）
- 📏距離計算ボタンは引き続き動作すること

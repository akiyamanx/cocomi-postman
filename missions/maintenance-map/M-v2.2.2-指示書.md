<!-- dest: missions/maintenance-map -->
# maintenance-map-ap v2.2.2 修正指示書
# ドラッグ&ドロップ復活＋ポップアップ起動＋CSV項目修正

## 概要
v2.2.1の修正で以下の問題がある:
1. ポップアップに営業所・型式・交換フィルターが表示されない（CSV検出ロジックまたはフィールド保存の問題）
2. 訪問順設定がドロップダウン数字選択になっているが、ドラッグ&ドロップ（会社名スライド並べ替え）方式に戻す
3. ドラッグ&ドロップのモーダルはルートタブからではなく、地図ポップアップの「訪問順を編集」ボタンから開く

## 重要ルール
- 1ファイル500行以内厳守
- コメントは日本語で書く
- 変更したファイルにはバージョンコメントを入れる（例：// v2.2.2修正）
- 既存コードの動作を破壊しない

## 変更対象ファイル
1. csv-handler.js — detectColumns()の4項目検出を修正・確認
2. map-core.js — ポップアップのドロップダウンを「訪問順を編集」ボタンに変更、4項目表示の修正
3. route-order.js — ドラッグ&ドロップのstartEdit/renderSortableListを復活させる
4. route-manager.js — ルートタブの🔢ボタンは削除のまま（確認専用維持）
5. sw.js — CACHE_NAME更新

---

## 1. csv-handler.js の修正

### 問題点
detectColumns()で営業所・型式・交換フィルターが正しく検出されていない可能性がある。
Excelのヘッダー行（4行目）は以下の通り:
- A列: 営業所
- B列: 型式
- C列: U管理NO
- D列: 交換フィルター
- E列: 設置先会社名
- F列: 都道府県
- G列: 住所
- H列: 設置先TEL
- I列: 受付担当者
- J列: 設置先情報

ただしExcelの実際のヘッダー行は4行目であり、1〜3行目はタイトル行。
SheetJSのsheet_to_json({header:1})は全行を配列として返すので、
processRows()でヘッダー行を正しく検出する必要がある。

### 1-1. detectColumns()のmapオブジェクトに3項目を追加

現在のmapオブジェクトを確認し、以下のフィールドが**なければ追加**する:
```javascript
const map = {
    company: -1,
    address: -1,
    phone: -1,
    contact: -1,
    note: -1,
    managementNo: -1,
    // v2.2.2追加
    branch: -1,        // 営業所
    equipType: -1,     // 型式（タンク/直結など）
    filter: -1,        // 交換フィルター
    prefecture: -1     // 都道府県
};
```

### 1-2. detectColumns()のforループに検出ルールを追加

既存のelse ifチェーンの**末尾**（managementNoの判定の後）に以下を追加:

```javascript
// v2.2.2追加 - 営業所の検出
if (map.branch === -1 && (h.includes('営業所') || h.includes('支店') || h.includes('branch'))) {
    map.branch = i;
}
// v2.2.2追加 - 型式の検出（「型式」にマッチ、「交換機種」は除外）
if (map.equipType === -1 && (h === '型式' || h.includes('型式')) && !h.includes('交換')) {
    map.equipType = i;
}
// v2.2.2追加 - 交換フィルターの検出
if (map.filter === -1 && (h.includes('フィルター') || h.includes('交換フィルター') || h.includes('filter'))) {
    map.filter = i;
}
// v2.2.2追加 - 都道府県の検出
if (map.prefecture === -1 && (h.includes('都道府県') || h.includes('prefecture'))) {
    map.prefecture = i;
}
```

**重要:** これらはelse ifチェーンの外に独立したif文として追加する。
理由: 既存のelse ifチェーンは最初にマッチした条件で分岐が終わるため、
「型式」が「管理」や他の条件に先にマッチしてしまう可能性がある。

### 1-3. processRows()の顧客オブジェクト構築を修正

customerオブジェクトに3フィールドを追加する。
現在の `managementNo: colMap.managementNo >= 0 ? ...` の行の後に追加:

```javascript
// v2.2.2追加
branch: colMap.branch >= 0 ? String(row[colMap.branch] || '').trim() : '',
equipType: colMap.equipType >= 0 ? String(row[colMap.equipType] || '').trim() : '',
filter: colMap.filter >= 0 ? String(row[colMap.filter] || '').trim() : ''
```

### 1-4. processRows()のaddress構築で都道府県を結合

Excelでは都道府県(F列)と住所(G列)が分かれている。
processRows()内のaddress取得部分を以下に変更:

現在:
```javascript
const address = colMap.address >= 0 ? String(row[colMap.address] || '').trim() : '';
```

変更後:
```javascript
// v2.2.2変更 - 都道府県と住所を結合
let address = colMap.address >= 0 ? String(row[colMap.address] || '').trim() : '';
if (colMap.prefecture >= 0) {
    const pref = String(row[colMap.prefecture] || '').trim();
    if (pref && address && !address.startsWith(pref)) {
        address = pref + address;
    }
}
```

### 1-5. ヘッダー行の自動検出を改善

Excelファイルでは1〜3行目がタイトル行で、4行目がヘッダー行。
現在のprocessRows()は `rows[0]` をヘッダーとして使っているが、
「会社」「住所」等のキーワードを含む行を自動検出するように改善する。

processRows()の先頭部分を以下に変更:

```javascript
function processRows(rows) {
    if (rows.length < 2) {
        alert('データが見つかりません。');
        return;
    }

    // v2.2.2改善 - ヘッダー行を自動検出（「会社」「住所」「設置先」を含む行を探す）
    let headerRowIdx = 0;
    for (let i = 0; i < Math.min(rows.length, 10); i++) {
        const rowStr = rows[i].map(c => String(c || '')).join('').toLowerCase();
        if (rowStr.includes('会社') || rowStr.includes('設置先') || rowStr.includes('住所')) {
            headerRowIdx = i;
            break;
        }
    }

    const header = rows[headerRowIdx].map(h => String(h || '').trim());
    const colMap = detectColumns(header);

    if (colMap.company === -1 && colMap.address === -1) {
        alert('会社名または住所の列が見つかりません。');
        return;
    }

    const dataRows = rows.slice(headerRowIdx + 1).filter(r => r.length > 1 && r.some(c => c));
    // ... 以降は既存コードと同じ
```

---

## 2. map-core.js の修正

### 2-1. showInfoWindow()に4項目の表示を追加/修正

showInfoWindow()内で、managementNoの表示の後に以下を追加。
既にv2.2.1で追加されている場合は内容を確認して修正する:

```javascript
// v2.2.2追加 - 営業所
if (customer.branch) html += `<p>🏢 営業所: ${customer.branch}</p>`;
// v2.2.2追加 - 型式
if (customer.equipType) html += `<p>⚙️ 型式: ${customer.equipType}</p>`;
// v2.2.2追加 - 交換フィルター
if (customer.filter) html += `<p>🔧 フィルター: ${customer.filter}</p>`;
```

注意: 既存の `if (customer.model)` 行（v1.0互換の機種名）とは別物。
customer.modelは残す。customer.equipTypeは新規追加のExcel型式列。

### 2-2. ポップアップの訪問順ドロップダウンを「訪問順を編集」ボタンに変更

現在のv2.2.1で追加されたドロップダウン部分（`info-visit-order`のdiv）を
以下のボタンに**置き換える**:

```javascript
// v2.2.2変更 - 訪問順編集ボタン（ドラッグ&ドロップモーダルを開く）
if (customer.routeId) {
    const currentRoute = routes.find(r => r.id === customer.routeId);
    const currentOrder = currentRoute && currentRoute.order ? currentRoute.order : [];
    const currentIdx = currentOrder.indexOf(customer.id);
    const orderText = currentIdx >= 0 ? `${currentIdx + 1}番目` : '未設定';

    html += `<div class="info-visit-order">`;
    html += `<span>🔢 訪問順: ${orderText}</span>`;
    html += `<button class="info-btn info-btn-order" onclick="RouteOrder.startEdit('${customer.routeId}')">並べ替え</button>`;
    html += `</div>`;
}
```

---

## 3. route-order.js の修正

### 3-1. ドラッグ&ドロップ機能を復活させる

v2.2.1でドラッグ&ドロップを削除してしまったので、v2.2（元のコード）のstartEdit、
renderSortableList、initDragAndDrop、updateNumbers、saveOrder、cancelEditを復活させる。

route-order.jsを以下の内容に**全面置き換え**する:

```javascript
// ============================================
// メンテナンスマップ v2.2.2 - route-order.js
// ルート訪問順管理（ドラッグ&ドロップ＋区間道路種別）
// v2.2新規作成 → v2.2.1ドロップダウン化 → v2.2.2ドラッグ&ドロップ復活
// ポップアップの「並べ替え」ボタンからモーダルを開く方式
// ============================================

const RouteOrder = (() => {
    // v2.2.2 - 訪問順編集モードの状態
    let editingRouteId = null;

    // v2.2.2 - 訪問順編集モードを開始する（ポップアップのボタンから呼ばれる）
    function startEdit(routeId) {
        editingRouteId = routeId;
        renderSortableList(routeId);
    }

    // v2.2.2 - 並び替えリストをモーダルで描画する
    function renderSortableList(routeId) {
        const routes = DataStorage.getRoutes();
        const route = routes.find(r => r.id === routeId);
        const customers = DataStorage.getCustomers();
        const members = customers.filter(c => c.routeId === routeId);

        if (members.length === 0) return;

        // v2.2.2 - orderがあればその順番で並べ替え
        const ordered = [];
        if (route.order && route.order.length > 0) {
            for (const cid of route.order) {
                const found = members.find(m => m.id === cid);
                if (found) ordered.push(found);
            }
            for (const m of members) {
                if (!ordered.find(o => o.id === m.id)) ordered.push(m);
            }
        } else {
            ordered.push(...members);
        }

        // v2.2.2 - モーダルHTML生成
        let html = '<div class="ro-modal-overlay" id="routeOrderModal">';
        html += '<div class="ro-modal">';
        html += `<h3>🔢 ${route.name} の訪問順</h3>`;
        html += '<p class="ro-hint">長押しでドラッグして順番を変更</p>';
        html += '<div class="ro-list" id="roSortList">';

        ordered.forEach((m, idx) => {
            html += `<div class="ro-item" data-id="${m.id}" draggable="true">`;
            html += `<span class="ro-num">${idx + 1}</span>`;
            html += `<span class="ro-grip">☰</span>`;
            html += `<span class="ro-name">${m.company || '不明'}`;
            if (m.unitCount > 1) html += ` (${m.unitCount}台)`;
            html += `</span>`;
            html += '</div>';
        });

        html += '</div>';
        html += '<div class="ro-actions">';
        html += '<button class="ro-btn ro-btn-cancel" onclick="RouteOrder.cancelEdit()">キャンセル</button>';
        html += '<button class="ro-btn ro-btn-save" onclick="RouteOrder.saveOrder()">✅ 保存</button>';
        html += '</div>';
        html += '</div></div>';

        const existing = document.getElementById('routeOrderModal');
        if (existing) existing.remove();
        document.body.insertAdjacentHTML('beforeend', html);
        initDragAndDrop();
    }

    // v2.2.2 - HTML5 Drag and Drop + タッチ対応の初期化
    function initDragAndDrop() {
        const list = document.getElementById('roSortList');
        if (!list) return;
        let dragItem = null;

        // --- マウス/HTML5 DnD ---
        list.addEventListener('dragstart', (e) => {
            dragItem = e.target.closest('.ro-item');
            if (!dragItem) return;
            dragItem.classList.add('ro-dragging');
            e.dataTransfer.effectAllowed = 'move';
        });

        list.addEventListener('dragover', (e) => {
            e.preventDefault();
            const target = e.target.closest('.ro-item');
            if (target && target !== dragItem) {
                const rect = target.getBoundingClientRect();
                const mid = rect.top + rect.height / 2;
                if (e.clientY < mid) {
                    list.insertBefore(dragItem, target);
                } else {
                    list.insertBefore(dragItem, target.nextSibling);
                }
            }
        });

        list.addEventListener('dragend', () => {
            if (dragItem) dragItem.classList.remove('ro-dragging');
            dragItem = null;
            updateNumbers();
        });

        // --- タッチ対応 ---
        let touchItem = null;

        list.addEventListener('touchstart', (e) => {
            const item = e.target.closest('.ro-item');
            if (!item) return;
            touchItem = item;
            touchItem.classList.add('ro-dragging');
        }, { passive: true });

        list.addEventListener('touchmove', (e) => {
            if (!touchItem) return;
            e.preventDefault();
            const touchY = e.touches[0].clientY;
            const items = [...list.querySelectorAll('.ro-item:not(.ro-dragging)')];
            for (const item of items) {
                const rect = item.getBoundingClientRect();
                const mid = rect.top + rect.height / 2;
                if (touchY < mid) {
                    list.insertBefore(touchItem, item);
                    break;
                }
                if (item === items[items.length - 1] && touchY >= mid) {
                    list.appendChild(touchItem);
                }
            }
        }, { passive: false });

        list.addEventListener('touchend', () => {
            if (touchItem) touchItem.classList.remove('ro-dragging');
            touchItem = null;
            updateNumbers();
        });
    }

    // v2.2.2 - 番号を振り直す
    function updateNumbers() {
        const items = document.querySelectorAll('#roSortList .ro-item');
        items.forEach((item, idx) => {
            item.querySelector('.ro-num').textContent = idx + 1;
        });
    }

    // v2.2.2 - 順序を保存する
    function saveOrder() {
        if (!editingRouteId) return;
        const items = document.querySelectorAll('#roSortList .ro-item');
        const order = [...items].map(item => item.dataset.id);

        DataStorage.updateRouteOrder(editingRouteId, order);
        cancelEdit();
        RouteManager.updateRoutePanel();
        alert('✅ 訪問順を保存しました！');
    }

    // v2.2.2 - 編集をキャンセルする
    function cancelEdit() {
        editingRouteId = null;
        const modal = document.getElementById('routeOrderModal');
        if (modal) modal.remove();
    }

    // v2.2.2 - 区間道路種別エディタを表示する
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
        html += '</div></div></div>';

        RouteOrder._segRouteId = routeId;
        RouteOrder._segData = { ...routeSegments };

        const existing = document.getElementById('segmentEditorModal');
        if (existing) existing.remove();
        document.body.insertAdjacentHTML('beforeend', html);
    }

    // v2.2.2 - 区間の道路種別を切り替える
    function setSegType(segKey, type, btn) {
        RouteOrder._segData[segKey] = type;
        const parent = btn.parentElement;
        parent.querySelectorAll('.seg-btn').forEach(b => b.classList.remove('seg-btn-active'));
        btn.classList.add('seg-btn-active');
    }

    // v2.2.2 - 区間データを保存する
    function saveSegments() {
        const routeId = RouteOrder._segRouteId;
        if (!routeId) return;
        const allSegments = DataStorage.getSegments();
        allSegments[routeId] = RouteOrder._segData;
        DataStorage.saveSegments(allSegments);
        closeSegmentEditor();
        alert('✅ 区間の道路種別を保存しました！');
    }

    // v2.2.2 - 区間エディタを閉じる
    function closeSegmentEditor() {
        const modal = document.getElementById('segmentEditorModal');
        if (modal) modal.remove();
    }

    // v2.2.2 - 公開API
    return {
        startEdit, saveOrder, cancelEdit,
        showSegmentEditor, setSegType, saveSegments, closeSegmentEditor
    };
})();
```

---

## 4. route-order-styles.css の修正

ドラッグ&ドロップ用のスタイルが削除されていたら復活させる。
以下のスタイルが存在することを確認し、なければ追加する:

```css
/* v2.2.2 - ドラッグ&ドロップ用スタイル */
.ro-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 12px;
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    margin-bottom: 6px;
    cursor: grab;
    transition: transform 0.15s, box-shadow 0.15s;
    user-select: none;
    -webkit-user-select: none;
}

.ro-item.ro-dragging {
    opacity: 0.5;
    background: #dbeafe;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    transform: scale(1.02);
}

.ro-num {
    width: 24px;
    height: 24px;
    background: #3b82f6;
    color: white;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: 700;
    flex-shrink: 0;
}

.ro-grip {
    color: #94a3b8;
    font-size: 16px;
    cursor: grab;
}

.ro-name {
    flex: 1;
    font-size: 14px;
    font-weight: 500;
}
```

また、ポップアップの訪問順ボタン用スタイルを追加:

```css
/* v2.2.2追加 - ポップアップ内訪問順ボタン */
.info-visit-order {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    margin: 8px 0;
    padding: 6px 8px;
    background: #f0f9ff;
    border-radius: 6px;
    font-size: 13px;
}

.info-btn-order {
    background: #3b82f6 !important;
    color: white !important;
    border: none;
    padding: 4px 10px;
    border-radius: 4px;
    font-size: 12px;
    cursor: pointer;
}
```

---

## 5. sw.js の変更

CACHE_NAMEを更新:
```javascript
const CACHE_NAME = 'maintenance-map-v2.2.2';
```

---

## 確認事項
- Excelを再読み込みして営業所・型式・交換フィルターがポップアップに表示されること
- ポップアップの「並べ替え」ボタンをタップするとドラッグ&ドロップモーダルが開くこと
- モーダルで会社名をスライドして訪問順を変更できること
- 保存後、ルートタブに反映されること
- ルートタブからは順番変更できないこと（確認専用）

<!-- dest: missions/maintenance-map -->
# maintenance-map-ap v2.2 アップグレード指示書
# 訪問順設定＋区間道路種別＋走行距離計算＋ETC明細読込

## 概要
メンテナンスマップv2.1（精算書統合済み）に以下4機能を追加してv2.2にする。
全6ステップで段階的に実装。各ステップ完了時点でアプリは正常動作すること。

## 重要ルール
- 1ファイル500行以内厳守。超えそうなら新規ファイルに分離する
- コメントは日本語で書く
- 各ファイル先頭にバージョン番号を記載する（v2.2）
- 既存コードの動作を破壊しない（後方互換性を維持）
- 変更したファイルにはバージョンコメントを入れる（例：// v2.2追加）
- sw.jsのCACHE_NAMEを最終ステップで更新する

## 現在のファイル構成と行数（超過注意）
- index.html: 265行
- styles.css: 412行 ← 追加余地88行！新スタイルは別CSSファイルに
- data-storage.js: 303行
- csv-handler.js: 221行
- map-core.js: 441行 ← 追加余地59行！大きな追加は別ファイルに
- route-manager.js: 293行
- expense-form.js: 約310行
- expense-pdf.js: 約200行
- expense-styles.css: 約130行
- ui-actions.js: 169行
- sw.js: 63行

---

### Step 1/6: 訪問順設定機能（route-manager.js改修 + route-order.js新規）

**目的:** ルートタブで各ルート内の顧客の訪問順をドラッグ&ドロップで変更できるようにする。
順序はルートのorderプロパティ（顧客IDの配列）に保存する。

**変更ファイル:** route-manager.js, data-storage.js
**新規ファイル:** route-order.js

#### 1-1. data-storage.js に順序保存メソッド追加

saveRoutes()は既にあるので、ルートのorder配列を使う。
DEFAULT_ROUTESの各ルートには既に `order: []` がある。

data-storage.jsの公開APIの直前（returnの前）に以下を追加:

```javascript
// v2.2追加 - ルートの訪問順を更新
function updateRouteOrder(routeId, orderArray) {
    const routes = getRoutes();
    const route = routes.find(r => r.id === routeId);
    if (route) {
        route.order = orderArray;
        saveRoutes(routes);
    }
}
```

returnオブジェクトにも `updateRouteOrder` を追加する。

#### 1-2. route-order.js を新規作成

タッチ対応のドラッグ&ドロップ並び替えを実装する。

```javascript
// ============================================
// メンテナンスマップ v2.2 - route-order.js
// ルート内の訪問順ドラッグ&ドロップ管理
// v2.2新規作成
// ============================================

const RouteOrder = (() => {
    // 訪問順編集モードの状態
    let editingRouteId = null;

    // v2.2 - 訪問順編集モードを開始する
    function startEdit(routeId) {
        editingRouteId = routeId;
        renderSortableList(routeId);
    }

    // v2.2 - 並び替えリストを描画する
    function renderSortableList(routeId) {
        const routes = DataStorage.getRoutes();
        const route = routes.find(r => r.id === routeId);
        const customers = DataStorage.getCustomers();
        const members = customers.filter(c => c.routeId === routeId);

        if (members.length === 0) return;

        // orderがあればその順番で並べ替え、なければ現状の順
        const ordered = [];
        if (route.order && route.order.length > 0) {
            for (const cid of route.order) {
                const found = members.find(m => m.id === cid);
                if (found) ordered.push(found);
            }
            // orderに含まれない新メンバーを末尾に追加
            for (const m of members) {
                if (!ordered.find(o => o.id === m.id)) ordered.push(m);
            }
        } else {
            ordered.push(...members);
        }

        // モーダルで表示
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

        // 既存のモーダルがあれば削除
        const existing = document.getElementById('routeOrderModal');
        if (existing) existing.remove();

        document.body.insertAdjacentHTML('beforeend', html);
        initDragAndDrop();
    }

    // v2.2 - HTML5 Drag and Drop + タッチ対応の初期化
    function initDragAndDrop() {
        const list = document.getElementById('roSortList');
        if (!list) return;
        let dragItem = null;
        let placeholder = null;

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
        let touchStartY = 0;
        let touchClone = null;

        list.addEventListener('touchstart', (e) => {
            const item = e.target.closest('.ro-item');
            if (!item) return;
            touchItem = item;
            touchStartY = e.touches[0].clientY;
            // 長押し判定は省略、即ドラッグ可能にする
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

    // v2.2 - 番号を振り直す
    function updateNumbers() {
        const items = document.querySelectorAll('#roSortList .ro-item');
        items.forEach((item, idx) => {
            item.querySelector('.ro-num').textContent = idx + 1;
        });
    }

    // v2.2 - 順序を保存する
    function saveOrder() {
        if (!editingRouteId) return;
        const items = document.querySelectorAll('#roSortList .ro-item');
        const order = [...items].map(item => item.dataset.id);

        DataStorage.updateRouteOrder(editingRouteId, order);
        cancelEdit();
        RouteManager.updateRoutePanel();
        alert('✅ 訪問順を保存しました！');
    }

    // v2.2 - 編集をキャンセルする
    function cancelEdit() {
        editingRouteId = null;
        const modal = document.getElementById('routeOrderModal');
        if (modal) modal.remove();
    }

    return { startEdit, saveOrder, cancelEdit };
})();
```

#### 1-3. route-manager.js のルートヘッダーに「順序編集」ボタンを追加

updateRoutePanel()関数内のルートヘッダー部分（route-headerのdiv）に、
メンバーが2件以上のルートには順序編集ボタンを追加する。

現在の route-header 行:
```javascript
html += `<span class="route-count">${members.length}件</span>`;
```
の直後に追加:
```javascript
// v2.2追加 - 訪問順編集ボタン（2件以上で表示）
if (members.length >= 2) {
    html += `<button class="route-order-btn" onclick="event.stopPropagation();RouteOrder.startEdit('${route.id}')">🔢</button>`;
}
```

またルートパネルでメンバー表示時、orderがあればその順で表示するよう改修:
現在の `const members = customers.filter(c => c.routeId === route.id);` の直後に:
```javascript
// v2.2追加 - order配列がある場合は訪問順で並べ替え
if (route.order && route.order.length > 0) {
    members.sort((a, b) => {
        const ai = route.order.indexOf(a.id);
        const bi = route.order.indexOf(b.id);
        return (ai === -1 ? 999 : ai) - (bi === -1 ? 999 : bi);
    });
}
```

#### 1-4. route-order-styles.css を新規作成

訪問順モーダル用のスタイル。以下の内容で作成:

```css
/* ============================================
 * メンテナンスマップ v2.2 - route-order-styles.css
 * 訪問順ドラッグ&ドロップモーダルのスタイル
 * v2.2新規作成
 * ============================================ */

.ro-modal-overlay {
    position: fixed; inset: 0;
    background: rgba(0,0,0,0.5);
    display: flex; align-items: center; justify-content: center;
    z-index: 600; padding: 16px;
}

.ro-modal {
    background: var(--surface); border-radius: 16px;
    padding: 20px; width: 100%; max-width: 400px;
    max-height: 80vh; overflow-y: auto;
    box-shadow: var(--shadow-lg);
}

.ro-modal h3 { font-size: 16px; margin-bottom: 4px; }
.ro-hint { font-size: 11px; color: var(--text-light); margin-bottom: 12px; }

.ro-list { min-height: 50px; }

.ro-item {
    display: flex; align-items: center; gap: 10px;
    padding: 12px; margin-bottom: 6px;
    background: var(--bg); border-radius: 8px;
    border: 2px solid transparent;
    cursor: grab; user-select: none;
    transition: border-color 0.15s, background 0.15s;
}

.ro-item.ro-dragging {
    opacity: 0.5; border-color: var(--primary);
    background: #e0e7ff;
}

.ro-num {
    width: 28px; height: 28px; border-radius: 50%;
    background: var(--primary); color: white;
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; font-weight: 700; flex-shrink: 0;
}

.ro-grip { font-size: 18px; color: var(--text-light); flex-shrink: 0; }
.ro-name { font-size: 14px; font-weight: 500; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.ro-actions { display: flex; gap: 8px; margin-top: 16px; }
.ro-btn {
    flex: 1; padding: 11px; border: none; border-radius: 8px;
    font-size: 14px; font-weight: 700; cursor: pointer;
    font-family: var(--font);
}
.ro-btn-cancel { background: var(--bg); color: var(--text); }
.ro-btn-save { background: var(--primary); color: white; }

.route-order-btn {
    background: var(--primary); color: white;
    border: none; border-radius: 6px;
    padding: 3px 8px; font-size: 12px;
    cursor: pointer; margin-left: 4px;
}
```

#### 1-5. index.html に新ファイルの読込を追加

`<link rel="stylesheet" href="expense-styles.css">` の直後に:
```html
<link rel="stylesheet" href="route-order-styles.css">
```

`<script src="expense-pdf.js"></script>` の直後に:
```html
<script src="route-order.js"></script>
```

**テスト方法:**
1. ルートタブを開く
2. 2件以上のルートに🔢ボタンが表示される
3. 🔢をタップすると訪問順モーダルが開く
4. ドラッグで順番を変更して保存
5. ルートパネルの表示順が変わる

---

### Step 2/6: 区間ごとの道路種別選択（route-order.jsに追加）

**目的:** 訪問順を保存した後、各区間（A→B、B→C...）に「高速」「下道」を設定できるUIを追加する。
データはdata-storage.jsのsegmentsに保存する。

**変更ファイル:** route-order.js, data-storage.js

#### 2-1. route-order.js の saveOrder() を改修

saveOrder()の最後（alert後）に区間設定UIを自動で開く:

```javascript
// saveOrder内、alert('✅ 訪問順を保存しました！')の直後に追加:
// v2.2追加 - 保存後に区間道路種別設定を開く
setTimeout(() => showSegmentEditor(editingRouteId, order), 300);
```

ただしeditingRouteIdはsaveOrder内でnullにしているのでその前にローカル変数に保存すること。

#### 2-2. route-order.js に区間エディタを追加

route-order.jsのreturnの前に以下の関数群を追加:

```javascript
// v2.2追加 - 区間道路種別エディタを表示する
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

    // routeIdを保持
    RouteOrder._segRouteId = routeId;
    RouteOrder._segData = { ...routeSegments };

    const existing = document.getElementById('segmentEditorModal');
    if (existing) existing.remove();
    document.body.insertAdjacentHTML('beforeend', html);
}

// v2.2追加 - 区間の道路種別を切り替える
function setSegType(segKey, type, btn) {
    RouteOrder._segData[segKey] = type;
    const parent = btn.parentElement;
    parent.querySelectorAll('.seg-btn').forEach(b => b.classList.remove('seg-btn-active'));
    btn.classList.add('seg-btn-active');
}

// v2.2追加 - 区間データを保存する
function saveSegments() {
    const routeId = RouteOrder._segRouteId;
    if (!routeId) return;
    const allSegments = DataStorage.getSegments();
    allSegments[routeId] = RouteOrder._segData;
    DataStorage.saveSegments(allSegments);
    closeSegmentEditor();
    alert('✅ 区間の道路種別を保存しました！');
}

// v2.2追加 - 区間エディタを閉じる
function closeSegmentEditor() {
    const modal = document.getElementById('segmentEditorModal');
    if (modal) modal.remove();
}
```

returnオブジェクトに `showSegmentEditor, setSegType, saveSegments, closeSegmentEditor` を追加。

#### 2-3. route-order-styles.css に区間エディタスタイルを追加

```css
/* v2.2追加 - 区間道路種別エディタ */
.seg-list { margin-bottom: 12px; }

.seg-item {
    padding: 10px; margin-bottom: 6px;
    background: var(--bg); border-radius: 8px;
}

.seg-label {
    font-size: 12px; font-weight: 600;
    margin-bottom: 6px; color: var(--text);
}

.seg-toggle { display: flex; gap: 6px; }

.seg-btn {
    flex: 1; padding: 8px; border: 2px solid var(--border);
    border-radius: 8px; background: var(--surface);
    font-size: 13px; font-weight: 600; cursor: pointer;
    font-family: var(--font); transition: all 0.15s;
}

.seg-btn-active {
    border-color: var(--primary); background: #e0e7ff;
    color: var(--primary);
}
```

**テスト方法:**
1. 訪問順を保存すると自動で区間エディタが開く
2. 各区間で「下道」「高速」を選択できる
3. 保存でLocalStorageのmm_segmentsに反映される

---

### Step 3/6: 走行距離計算モジュール新規作成（distance-calc.js）

**目的:** Google Maps Directions APIを使い、ルートの訪問順＋道路種別で走行距離を計算する。
結果を精算書に反映するボタンをUIに追加する。

**新規ファイル:** distance-calc.js

```javascript
// ============================================
// メンテナンスマップ v2.2 - distance-calc.js
// 走行距離計算モジュール（Directions API使用）
// v2.2新規作成
// ============================================

const DistanceCalc = (() => {
    // v2.2 - Directions APIで2点間の距離を取得する
    function getDistance(origin, destination, avoidHighways) {
        return new Promise((resolve, reject) => {
            const service = new google.maps.DirectionsService();
            service.route({
                origin: origin,
                destination: destination,
                travelMode: google.maps.TravelMode.DRIVING,
                avoidHighways: avoidHighways
            }, (result, status) => {
                if (status === 'OK' && result.routes[0]) {
                    const leg = result.routes[0].legs[0];
                    resolve({
                        distanceM: leg.distance.value,
                        distanceKm: Math.round(leg.distance.value / 1000),
                        distanceText: leg.distance.text,
                        durationSec: leg.duration.value,
                        durationText: leg.duration.text
                    });
                } else {
                    reject(new Error('Directions API error: ' + status));
                }
            });
        });
    }

    // v2.2 - ルート全体の走行距離を計算する
    // homeAddress（出発地）→ 訪問順の各顧客 → homeAddress（帰着）
    async function calcRouteDistance(routeId) {
        const routes = DataStorage.getRoutes();
        const route = routes.find(r => r.id === routeId);
        if (!route) throw new Error('ルートが見つかりません');

        const customers = DataStorage.getCustomers();
        const members = customers.filter(c => c.routeId === routeId);
        if (members.length === 0) throw new Error('ルートにメンバーがいません');

        // 訪問順で並べ替え
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

        // 自宅住所を取得
        const settings = DataStorage.getSettings();
        const homeAddress = settings.homeAddress;
        if (!homeAddress) throw new Error('設定で自宅住所（出発点）を登録してください');

        // 区間データ取得
        const allSegments = DataStorage.getSegments();
        const routeSegments = allSegments[routeId] || {};

        // 全ポイントリスト: 自宅 → 各顧客 → 自宅
        const points = [];
        points.push({ address: homeAddress, id: 'home_start' });
        ordered.forEach(m => points.push({ address: m.address, id: m.id }));
        points.push({ address: homeAddress, id: 'home_end' });

        // 区間ごとに距離計算
        let totalKm = 0;
        let highwayKm = 0;
        let generalKm = 0;
        const segments = [];

        for (let i = 0; i < points.length - 1; i++) {
            const from = points[i];
            const to = points[i + 1];

            // 区間の道路種別を判定
            const segKey = `${from.id}_${to.id}`;
            const segType = routeSegments[segKey] || 'general';
            const avoidHighways = (segType === 'general');

            // Directions API呼び出し（レート制限対策で500ms間隔）
            if (i > 0) await sleep(500);

            try {
                const result = await getDistance(from.address, to.address, avoidHighways);
                const seg = {
                    from: from.address.substring(0, 20),
                    to: to.address.substring(0, 20),
                    type: segType,
                    km: result.distanceKm,
                    duration: result.durationText
                };
                segments.push(seg);
                totalKm += result.distanceKm;
                if (segType === 'highway') highwayKm += result.distanceKm;
                else generalKm += result.distanceKm;
            } catch (err) {
                console.warn(`区間距離計算失敗: ${from.address} → ${to.address}`, err);
                segments.push({
                    from: from.address.substring(0, 20),
                    to: to.address.substring(0, 20),
                    type: segType,
                    km: 0,
                    duration: '計算失敗',
                    error: true
                });
            }
        }

        return { totalKm, highwayKm, generalKm, segments };
    }

    // v2.2 - 待機関数
    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    return { getDistance, calcRouteDistance };
})();
```

**index.htmlに追加（expense-pdf.jsの後）:**
```html
<script src="distance-calc.js"></script>
```

**テスト方法:**
- この時点ではUIから呼べないが、ブラウザコンソールで動作確認可能:
  `DistanceCalc.calcRouteDistance('route_1').then(r => console.log(r))`

---

### Step 4/6: 走行距離計算UIと精算書連携（route-manager.js改修）

**目的:** ルートパネルに「距離計算」ボタンを追加し、計算結果を表示＆精算書に反映する。

**変更ファイル:** route-manager.js

#### 4-1. ルートヘッダーに距離計算ボタンを追加

updateRoutePanel()内、訪問順ボタンの直後に追加:

```javascript
// v2.2追加 - 距離計算ボタン（2件以上＋訪問順設定済みで表示）
if (members.length >= 2 && route.order && route.order.length >= 2) {
    html += `<button class="route-dist-btn" onclick="event.stopPropagation();RouteManager.calcDistance('${route.id}')">📏</button>`;
}
```

#### 4-2. route-manager.js に距離計算実行関数を追加

returnの前に:

```javascript
// v2.2追加 - ルートの走行距離を計算して結果を表示する
async function calcDistance(routeId) {
    const loading = document.getElementById('loading');
    loading.style.display = 'flex';
    document.getElementById('loadingProgress').textContent = '走行距離計算中...';

    try {
        const result = await DistanceCalc.calcRouteDistance(routeId);

        loading.style.display = 'none';

        // 結果をalertで表示＋精算書に反映するか確認
        const routes = DataStorage.getRoutes();
        const route = routes.find(r => r.id === routeId);
        const routeName = route ? route.name : routeId;

        let msg = `📏 ${routeName} の走行距離\n\n`;
        msg += `総距離: ${result.totalKm}km\n`;
        msg += `  🚗 下道: ${result.generalKm}km\n`;
        msg += `  🛣️ 高速: ${result.highwayKm}km\n\n`;
        msg += `--- 区間詳細 ---\n`;
        result.segments.forEach((s, i) => {
            const icon = s.type === 'highway' ? '🛣️' : '🚗';
            msg += `${i + 1}. ${icon} ${s.km}km (${s.duration})\n`;
        });
        msg += `\n精算書に反映しますか？`;

        if (confirm(msg)) {
            applyDistanceToExpense(result.totalKm);
        }
    } catch (err) {
        loading.style.display = 'none';
        alert('❌ 距離計算に失敗しました\n' + err.message);
    }
}

// v2.2追加 - 計算した距離を精算書フォームに反映する
function applyDistanceToExpense(totalKm) {
    // 精算書タブに切り替え
    switchTab('expense');
    ExpenseForm.init();

    // 最初の行の走行距離に値を設定
    setTimeout(() => {
        const firstRow = document.querySelector('.exp-row');
        if (firstRow) {
            const distInput = firstRow.querySelector('.exp-distance');
            if (distInput) {
                distInput.value = totalKm;
                ExpenseForm.updateGas(distInput);
            }
        }
    }, 200);
}
```

returnオブジェクトに `calcDistance` を追加。

#### 4-3. route-order-styles.css に距離計算ボタンスタイルを追加

```css
/* v2.2追加 - 距離計算ボタン */
.route-dist-btn {
    background: var(--success); color: white;
    border: none; border-radius: 6px;
    padding: 3px 8px; font-size: 12px;
    cursor: pointer; margin-left: 2px;
}
```

**テスト方法:**
1. 訪問順設定済みのルートに📏ボタンが表示される
2. タップするとDirections API呼び出し→距離計算
3. 結果表示→「精算書に反映しますか？」→はい→精算書タブの走行距離に入力

---

### Step 5/6: ETC利用明細読込機能（etc-reader.js新規）

**目的:** ETC利用照会サービスからダウンロードしたCSVを読み込み、高速代を精算書に自動反映する。

**新規ファイル:** etc-reader.js

ETC利用照会のCSVフォーマット（一般的な形式）:
```
利用年月日,車種,入口IC,出口IC,利用額,割引額,最終額,ETCカード番号,...
2026/02/21,普通車,千葉北,逗子,2650,0,2650,...
```

```javascript
// ============================================
// メンテナンスマップ v2.2 - etc-reader.js
// ETC利用明細CSV読込・精算書自動反映モジュール
// v2.2新規作成
// ============================================

const EtcReader = (() => {

    // v2.2 - ETC明細CSVを読み込む
    function handleFile(event) {
        const file = event.target.files[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            const text = e.target.result;
            const records = parseEtcCsv(text);

            if (records.length === 0) {
                alert('❌ ETC明細データが見つかりませんでした。\nCSVの形式を確認してください。');
                return;
            }

            showEtcRecords(records);
        };
        // ETC利用照会はShift-JISの場合が多い
        reader.readAsText(file, 'Shift_JIS');
        event.target.value = '';
    }

    // v2.2 - ETC明細CSVをパースする
    // 複数のCSVフォーマットに対応（ヘッダー自動検出）
    function parseEtcCsv(text) {
        const lines = text.split(/\r?\n/).filter(l => l.trim());
        if (lines.length < 2) return [];

        const records = [];
        let dateCol = -1, entryCol = -1, exitCol = -1, amountCol = -1;

        // ヘッダー行を探す
        for (let i = 0; i < Math.min(5, lines.length); i++) {
            const cols = lines[i].split(',').map(c => c.replace(/"/g, '').trim());
            for (let j = 0; j < cols.length; j++) {
                const c = cols[j];
                if (c.includes('年月日') || c.includes('利用日') || c.includes('日付')) dateCol = j;
                if (c.includes('入口') || c.includes('入口IC')) entryCol = j;
                if (c.includes('出口') || c.includes('出口IC')) exitCol = j;
                if (c.includes('利用額') || c.includes('金額') || c.includes('最終額') || c.includes('通行料金')) {
                    amountCol = j;
                }
            }
            // ヘッダーが見つかったらその次の行からデータ
            if (dateCol >= 0 && amountCol >= 0) {
                for (let k = i + 1; k < lines.length; k++) {
                    const cols = lines[k].split(',').map(c => c.replace(/"/g, '').trim());
                    if (cols.length <= Math.max(dateCol, amountCol)) continue;

                    const dateStr = cols[dateCol] || '';
                    const amount = parseInt(cols[amountCol].replace(/[^0-9]/g, '')) || 0;

                    if (amount > 0) {
                        records.push({
                            date: dateStr,
                            entry: entryCol >= 0 ? cols[entryCol] : '',
                            exit: exitCol >= 0 ? cols[exitCol] : '',
                            amount: amount
                        });
                    }
                }
                break;
            }
        }

        // ヘッダーが見つからない場合、位置ベースで推定
        if (records.length === 0 && lines.length >= 2) {
            for (let i = 0; i < lines.length; i++) {
                const cols = lines[i].split(',').map(c => c.replace(/"/g, '').trim());
                // 日付っぽい列を探す
                const dateIdx = cols.findIndex(c => /\d{4}[\/\-]\d{1,2}[\/\-]\d{1,2}/.test(c));
                if (dateIdx >= 0) {
                    // 数値っぽい列を金額として使う
                    for (let j = cols.length - 1; j > dateIdx; j--) {
                        const val = parseInt(cols[j].replace(/[^0-9]/g, ''));
                        if (val > 0) {
                            records.push({
                                date: cols[dateIdx],
                                entry: cols[dateIdx + 1] || '',
                                exit: cols[dateIdx + 2] || '',
                                amount: val
                            });
                            break;
                        }
                    }
                }
            }
        }

        return records;
    }

    // v2.2 - 読み込んだETC明細を表示して選択させる
    function showEtcRecords(records) {
        const total = records.reduce((s, r) => s + r.amount, 0);

        let html = '<div class="ro-modal-overlay" id="etcModal">';
        html += '<div class="ro-modal">';
        html += '<h3>🛣️ ETC利用明細</h3>';
        html += `<p class="ro-hint">${records.length}件 合計 ¥${total.toLocaleString()}</p>`;
        html += '<div class="etc-list">';

        records.forEach((r, i) => {
            html += `<div class="etc-item">`;
            html += `<label>`;
            html += `<input type="checkbox" class="etc-check" data-idx="${i}" checked>`;
            html += `<span class="etc-info">`;
            html += `<span class="etc-date">${r.date}</span>`;
            html += `<span class="etc-route">${r.entry} → ${r.exit}</span>`;
            html += `</span>`;
            html += `<span class="etc-amount">¥${r.amount.toLocaleString()}</span>`;
            html += `</label>`;
            html += `</div>`;
        });

        html += '</div>';
        html += '<div class="ro-actions">';
        html += '<button class="ro-btn ro-btn-cancel" onclick="EtcReader.closeModal()">キャンセル</button>';
        html += '<button class="ro-btn ro-btn-save" onclick="EtcReader.applySelected()">✅ 精算書に反映</button>';
        html += '</div>';
        html += '</div></div>';

        // データを保持
        EtcReader._records = records;

        const existing = document.getElementById('etcModal');
        if (existing) existing.remove();
        document.body.insertAdjacentHTML('beforeend', html);
    }

    // v2.2 - 選択されたETC明細を精算書に反映する
    function applySelected() {
        const checks = document.querySelectorAll('.etc-check:checked');
        const records = EtcReader._records || [];
        let totalAmount = 0;
        const amounts = [];
        let count = 0;

        checks.forEach(chk => {
            const idx = parseInt(chk.dataset.idx);
            if (records[idx]) {
                totalAmount += records[idx].amount;
                amounts.push(records[idx].amount);
                count++;
            }
        });

        if (count === 0) {
            alert('反映するデータを選択してください');
            return;
        }

        closeModal();

        // 精算書タブに切り替えて反映
        switchTab('expense');
        ExpenseForm.init();

        setTimeout(() => {
            const firstRow = document.querySelector('.exp-row');
            if (firstRow) {
                // 高速代欄にカンマ区切りで入力
                const hwInput = firstRow.querySelector('.exp-highway');
                if (hwInput) {
                    hwInput.value = amounts.join(',');
                }
                // 枚数欄に件数を入力
                const countInput = firstRow.querySelector('.exp-hw-count');
                if (countInput) {
                    countInput.value = count;
                }
                // 交通機関欄に「高速道路」を設定
                const transportInput = firstRow.querySelector('.exp-transport');
                if (transportInput && !transportInput.value) {
                    transportInput.value = '高速道路';
                }
                ExpenseForm.calcTotals();
            }
            alert(`✅ ETC明細 ${count}件（¥${totalAmount.toLocaleString()}）を精算書に反映しました！`);
        }, 200);
    }

    // v2.2 - モーダルを閉じる
    function closeModal() {
        const modal = document.getElementById('etcModal');
        if (modal) modal.remove();
    }

    return { handleFile, applySelected, closeModal };
})();
```

**index.htmlに追加:**

スクリプト読込（distance-calc.jsの後）:
```html
<script src="etc-reader.js"></script>
```

**expense-form.js のETC関連ボタン周辺を改修:**

精算書パネル内の既存のETCリンクボタンの直後に、ETC読込ボタンを追加する。
renderExpensePanel()内のETC利用照会サービスリンクの直後に:

```html
<div style="display:flex;gap:8px;margin-bottom:10px;">
    <a href="https://www.etc-meisai.jp/" target="_blank"
       class="exp-etc-btn" style="flex:1;">
        🛣️ ETC照会を開く
    </a>
    <label class="exp-etc-btn" style="flex:1;background:linear-gradient(135deg,#0d7377,#14919b);cursor:pointer;">
        📂 ETC明細読込
        <input type="file" accept=".csv" style="display:none"
            onchange="EtcReader.handleFile(event)">
    </label>
</div>
```

既存の `<a>` タグ（ETC利用照会サービスを開く）は上記に置き換える。

#### route-order-styles.css にETC明細スタイルを追加:

```css
/* v2.2追加 - ETC明細リスト */
.etc-list { max-height: 300px; overflow-y: auto; margin-bottom: 12px; }

.etc-item { padding: 8px; border-bottom: 1px solid var(--border); }
.etc-item label {
    display: flex; align-items: center; gap: 8px;
    cursor: pointer; font-size: 13px;
}
.etc-check { width: 18px; height: 18px; flex-shrink: 0; }
.etc-info { flex: 1; min-width: 0; }
.etc-date { font-size: 11px; color: var(--text-light); display: block; }
.etc-route { font-size: 13px; font-weight: 500; }
.etc-amount { font-weight: 700; color: var(--primary); white-space: nowrap; }
```

**テスト方法:**
1. 精算書タブを開く
2. 「📂 ETC明細読込」ボタンが表示される
3. ETC利用照会からダウンロードしたCSVを選択
4. 明細一覧がモーダル表示→チェックで選択→「精算書に反映」
5. 高速代と枚数が精算書フォームに自動入力される

---

### Step 6/6: sw.js更新＋CLAUDE.md更新＋最終整合性チェック

**目的:** 新規ファイルをService Workerのキャッシュに追加し、ドキュメントを更新する。

**変更ファイル:** sw.js, CLAUDE.md, index.html（最終確認）

#### 6-1. sw.js のキャッシュバージョンとファイルリストを更新

```javascript
const CACHE_NAME = 'maintenance-map-v2.2.0';
const urlsToCache = [
    './',
    './index.html',
    './styles.css',
    './data-storage.js',
    './csv-handler.js',
    './map-core.js',
    './route-manager.js',
    './ui-actions.js',
    './expense-styles.css',
    './expense-form.js',
    './expense-pdf.js',
    './route-order.js',
    './route-order-styles.css',
    './distance-calc.js',
    './etc-reader.js',
    './manifest.json'
];
```

#### 6-2. CLAUDE.md を更新

ファイル構成テーブルに新規ファイルを追加:

```markdown
| `route-order.js` | 訪問順ドラッグ&ドロップ管理、区間道路種別エディタ |
| `route-order-styles.css` | 訪問順・区間・ETC明細モーダルのスタイル |
| `distance-calc.js` | Directions APIを使った走行距離計算 |
| `etc-reader.js` | ETC利用明細CSV読込・精算書自動反映 |
```

バージョンをv2.2に更新。

#### 6-3. index.html のtitleとスプラッシュのバージョンを更新

```html
<title>メンテナンスマップ v2.2</title>
```

スプラッシュ画面のバージョン:
```html
<p class="splash-ver">v2.2</p>
```

#### 6-4. manifest.json のバージョンを更新

```json
"name": "メンテナンスマップ v2.2",
"description": "ウォーターサーバーメンテナンス先を地図で管理＋交通費精算書＋走行距離計算アプリ",
```

#### 6-5. 最終チェック（全ファイルの行数確認）

```bash
echo "=== 500行チェック ==="
for f in *.js *.css *.html; do
    lines=$(wc -l < "$f")
    if [ "$lines" -gt 500 ]; then
        echo "❌ $f: ${lines}行（超過！）"
    else
        echo "✅ $f: ${lines}行"
    fi
done
```

500行超過のファイルがあれば分割すること。

**テスト方法:**
1. ページリロードでv2.2が表示される
2. 全タブ（リスト/ルート/集計/精算書）が正常動作
3. 訪問順設定→区間設定→距離計算→精算書反映の一連フローが通る
4. ETC明細読込→精算書反映が動作する
5. CIが全テスト通過する

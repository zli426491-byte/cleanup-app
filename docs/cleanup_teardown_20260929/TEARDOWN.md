# Cleanup（Codeway, v6.22.0）實機拆解 — 2026-09-29

來源：BrowserStack App Live，iPhone 15 Pro / iOS 17.3，菲律賓 App Store（價格顯示為 PHP）。
截圖編號對應本資料夾檔名；`00_appstore_screenshots.jpg` 是美區商店截圖（含重複/相似照片分組畫面，實機因相簿無重複照片未能拍到）。
付費牆只觀察，未訂閱、未開試用。

## 1. 視覺系統

| 項目 | 觀察 |
|---|---|
| 主色 | iOS 系統藍（約 #0A7AFF），所有主按鈕、PRO 膠囊、數字強調 |
| 背景 | 純白；卡片是極淡藍（約 #EEF3FD），無陰影、無邊框 |
| 危險/狀態 | 容量條紅色；刪除勾選是紅底白勾；成功是綠 |
| 字體 | SF Pro；大標題 28–34pt Heavy/Bold 靠左（iOS Large Title 風格）|
| 按鈕 | 滿寬藍色大按鈕，圓角約 16，固定在底部（Let's go / Delete N / Great）|
| 圓角 | 卡片約 20，縮圖約 16 |
| 插圖 | 3D 擬物插圖（彩帶筒、鎖、機器人、信封）+ 真人照片 |
| 語氣 | 極短句，無技術詞；只講結果（Space to Clean、Save 3 MB、Delete 1 Video）|

## 2. 資訊架構

底部 5 分頁：**Home / Email / Contacts / Optimize / Extras**。設定從首頁右上齒輪進入。

## 3. 流程

### 3.1 首次啟動（01–07）
1. 啟動立刻彈 ATT 追蹤授權。
2. `01` Welcome：Photos / iCloud 圖示 + 「? of 128 GB used」紅色容量條 + 隱私說明 + Get started。
3. `02` 按 Get started 才要相簿權限（權限說明寫明不上傳）。
4. `03–04` 3 步引導（頂部分段進度條）：Delete Duplicate Photos → (第二步自動輪播) → Clean Your Email Inbox。
5. `05` 過場「Try 7 days / For free!」。
6. `06` 付費牆 A：Photos/iCloud 紅點數字、容量條、Cleanup Pro 權益、「Free trial enabled」、今天 $0 / 到期日金額、Try Free；左上 Restore、右上小 X。
7. `07` 關掉後進首頁，才彈通知權限。

### 3.2 首頁（08–09）
- 頂部固定：「✦ Cleanup」+ 藍色 PRO 膠囊 + 齒輪；**「23.7 MB Space to Clean」+ 紅色容量條**（右側彩色點）。
- 藍色滿寬橫幅「Optimize Storage — Free up space from your files quickly >」。
- 分類：空的分類變淡；Similars、Duplicates 空時是滿寬單列；有內容的分類是 2 欄卡片，含縮圖 + 藍色膠囊「3 Videos (19.4 MB) >」。
- 分類順序：Similars、Duplicates、Videos、Similar Screenshots、Screenshots、Similar Videos、Blurred、Chat Photos、Other。

### 3.3 分類 → 刪除 → 恭喜（10–12、24–30）
1. 第一次進分類：插圖教學卡「Left to Delete / Right to Keep」+ 一句說明 + Let's go。
2. 網格：大標題 + 總大小；右上 Select；排序膠囊（Largest / Newest）；2 欄大縮圖，左下藍色大小標籤。
3. 影片分類頂部有「Video Compress — Tap to start the process — 9.7 MB >」入口。
4. 點單張：全螢幕預覽，頂部顯示大小與日期，右下勾選框；Other 類是滑動卡片，頂部提示泡泡「Swipe right to keep, swipe left to delete!」。
5. Select 模式：左上 Select All、右上 Cancel，選中是紅底白勾，底部「🗑 Delete 1 Video」。
6. `28` 按刪除 → **付費牆 B**：Unlock Unlimited Access、3 項權益、五星評論輪播、週訂閱（含 7 天試用）vs 終身（Save 89%）。**關掉後仍可刪除（軟牆）**。
7. `29` iOS 系統刪除確認。
8. `30` **Congratulations**：彩帶筒插圖、「You have deleted 1 Video (8.2 MB)」、「Saved 10 Minutes using Cleanup」、提醒清空「最近刪除」、Great。

### 3.4 聯絡人（14–19）
- 列表 4 列：All Contacts / Duplicates / Backups / Incomplete Contacts（每列有數量）。
- 重複聯絡人：每組一張卡，「2 Duplicate Contacts」+ 組內 Select All，勾選 → 底部「See Merge Preview」→ 合併預覽 → 「Merge 2 Contacts」→ **先問要不要備份** → 系統式二次確認 → 完成。免費可用（至少第一次）。

### 3.5 Optimize（20、22–23、31–32）
- Video Compress：列表顯示每支影片「Save 3 MB >」；詳情頁上方播放、下方「6.2 MB » 3.1 MB / You'll save about 3.1 MB」+ Low/Medium/High + Start Compress。**硬牆：必須訂閱**。
- Live to Still。
- Optimize Storage（首頁橫幅）：前後對比插圖 → 清單按 Duplicates / Similars / Similar Videos / Similar Screenshots 分區，可展開、各自 Select All。

### 3.6 Email（13）
只有「Sign in with Google」+「Your login is secured by Google」。

### 3.7 Extras（21、37–40）
- Utilities：Widgets（Battery / Storage / Both，3 種色系，Set Widget）、Charging Animation（2 欄動畫，付費款有星標）。
- Private：Secret Library（先建立 PIN 或 Maybe Later → 空狀態 + Add New）。
- From Developer：More Apps From Us。

### 3.8 設定（33–36）
付費大橫幅（機器人插圖 + Learn More）→ Account（Sign in）→ Secret Space（Use PIN、Remove After Import）→ Others（Vibration、Keep List…）→ FAQ / Email Support / Restore Purchase / About Us / Privacy / Terms / Refund Policy → More Apps → Rate / Share / Instagram → 「Cleanup by Codeway, version 6.22.0」。

## 4. 變現設計重點
- 兩個付費牆：引導結束的「試用型」（A）和操作時的「價值型」（B，含評論 + 終身方案錨定）。
- 軟牆：刪除、聯絡人合併讓你先用（體驗到爽點再收費）；影片壓縮是硬牆。
- 權限順序：ATT → 相簿（按鈕後）→ 通知（進首頁後）→ 聯絡人（進分頁時）。

## 5. 與 Codex 版（build 45）的主要差距
1. 視覺：綠色 Material 風格 vs Cleanup 的白底、淡藍卡片、系統藍、iOS 大標題。
2. 首頁：Codex 版是圓環圖 + 技術狀態；Cleanup 是「XX MB Space to Clean」+ 分類卡片牆。
3. 爽點：Codex 缺分類教學卡、底部「Delete N」固定按鈕、恭喜頁（刪了多少 + 省幾分鐘）。
4. 文案：Codex 有大量「驗證、原檔核對、待處理」等技術詞。
5. 缺功能：聯絡人（已停用）、Optimize Storage 一鍵總表、Blurred / Chat Photos / Similar Videos 分類、Widgets 前後台、付費牆 B。

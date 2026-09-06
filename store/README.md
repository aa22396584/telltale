# Google Play 上架素材

這裡的檔案是 Play Console listing 上傳過的原件。**這一份是來源，Play Console 上的是副本** ——
要換圖先換這裡，再上傳。

## 目錄

素材依 Play 的 listing 語系分開，因為 App 從 `1.0.11` 起是雙語的，而**截圖裡的字就是
listing 的一部分**。一份英文 listing 配一組中文截圖，等於在告訴讀者這個 App 沒有英文介面。

```
store/
├── en-US/          英文 listing 的素材
├── zh-TW/          繁體中文 listing 的素材
├── icon-512.png    兩邊共用：圖示沒有文字
└── preview-gt86-vin-redacted.mp4
```

`icon-512.png` 與預覽影片沒有進到語系目錄，因為它們裡面沒有任何一個字需要翻譯。
**不要為了目錄整齊而複製它們** —— 兩份會各自漂移，然後沒有人知道哪一份是真的。

| 檔案 | 尺寸 | 格式 | 用途 |
|---|---|---|---|
| `icon-512.png` | 512×512 | 32-bit PNG **含 alpha** | 應用程式圖示。Play 要求含 alpha，**不要**把它扁平化 |
| `<locale>/feature-1024x500.png` | 1024×500 | 24-bit PNG | 主打圖片（feature graphic） |
| `<locale>/01-connect.png` | 1080×2340 | 24-bit PNG | 手機截圖：選擇連線方式 |
| `<locale>/02-dashboard.png` | 1080×2340 | 24-bit PNG | 手機截圖：儀表板 |
| `<locale>/03-dtc-freeze.png` | 1080×2340 | 24-bit PNG | 手機截圖：故障碼與凍結幀 |
| `<locale>/05-performance.png` | 1080×2340 | 24-bit PNG | 手機截圖：性能量測 |
| `<locale>/06-skins.png` | 1080×2340 | 24-bit PNG | 手機截圖：語言與面盤外觀 |
| `preview-gt86-vin-redacted.mp4` | 1920×1080 | H.264 MP4 | Google Play YouTube 預覽影片來源；GT86 實車 VIN 已遮蔽 |

兩組截圖**畫面編號相同、內容刻意不同**。`en-US/06-skins.png` 取的是語言選單連同外觀設定，
因為對英文讀者來說「這個 App 有英文」本身就是新消息；`zh-TW/06-skins.png` 只取外觀。

## 怎麼重拍

英文那組是在 Pixel 9 模擬器（1080×2340，`wm size` 覆寫）上用 `field` debug build 拍的，
中文那組來自實機 Galaxy S24 Ultra。兩者尺寸相同，狀態列不同，這沒有關係 —— Play 不比對
兩個語系之間的一致性。

```bash
adb -s <serial> exec-out screencap -p > shot.png
```

`screencap` 出來是 32-bit RGBA，而 Play 的截圖規則要 24-bit 無 alpha。扁平化**只有在
alpha 全部是 255 時才是無損的**，所以要先驗再轉，不要直接轉：

```python
from PIL import Image
im = Image.open(src)
lo, hi = im.getchannel('A').getextrema()
assert (lo, hi) == (255, 255)          # 有真透明就停下來，不要壓黑底
im.convert('RGB').save(dst, 'PNG', optimize=True)
```

**不要用 `sips --setProperty hasAlpha false`。** 2026-09-06 實測：它對這五個檔沒有寫出
任何東西，而且 exit 0，`ls` 才看得出來檔案根本不存在。

## 隱私檢查

- `03-dtc-freeze.png` 顯示的是內建 Demo ECU 的固定測試 VIN
  `1D4GP00R55B123456`，不是實車或使用者資料。Play 商店目前可只使用其餘四張截圖；
  若要重新加入這張，應在素材文案中清楚標示為 Demo 資料。
- 原始 GT86 實車錄影曾短暫顯示真實 VIN，因此**不得直接上傳**。
  `preview-gt86-vin-redacted.mp4` 已裁掉 Android 狀態列與手勢列，將 VIN 欄位遮蔽，
  並以模糊背景輸出為 16:9 標準影片，避免被 YouTube 歸類為 Shorts。
  Play Console 的影片欄位只接受 YouTube 網址，應把這個遮蔽版上傳為公開或不公開影片，
  關閉廣告、允許嵌入且不設年齡限制。

## 為什麼沒有 `04-`

`git log --all --diff-filter=A --name-only -- 'store/*'` 證實 `04-*.png` **從未存在過** ——
不是被刪掉，是編號當初就跳過了。Play 的最低要求是兩張、建議至少四張，五張已經超過，
所以功能上不缺。留這一行是為了讓下一個人不用花十分鐘去確認自己有沒有漏檔。

## 已知與 Play 公布規則的落差（2026-08-18 實測）

**五張手機截圖是 2340/1080 = 2.167:1。** Play 的素材規則寫著「最長邊不得超過最短邊的兩倍」。
但這五張在 2026-08-18 **被 Play 接受了** —— listing 已發布到內部測試軌道，送審前檢查 0 issue。

這不是「規則不存在」，是規則的適用範圍和字面讀法不一致：現代手機螢幕普遍是 20:9（2.22:1），
一條 2:1 的硬上限會擋掉幾乎所有真實的手機截圖。所以這裡**刻意不重新裁切**：為了一條實測沒有
生效的規則去裁掉真實內容，比留著風險更糟。

下次更新 listing 若被擋，就把它們縮放並補邊到 1080×2160（正好 2.0:1，不裁切、不變形），
不要直接縮成 1080×1920 —— 那會壓扁畫面。

**alpha 已於 2026-08-18 處理。** 五張截圖原本是 32-bit RGBA，而規則要求「JPEG 或 24-bit PNG
（無 alpha）」。它們的 alpha 通道實測全部是 255（完全不透明），所以扁平化成 24-bit 是無損的，
已經做了（順帶少了約 300 KB）。`icon-512.png` 相反 —— 它的 alpha 是 0..255，**真的有透明區域**，
扁平化會在圖示後面壓上一塊黑底，而且 Play 的圖示規則本來就要 32-bit 含 alpha。不要動它。

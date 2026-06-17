# Diamond Transfer 機能紹介

**Diamond Transfer は、ローカルネットワークを前提にしたネイティブなファイル共有アプリです。2 台だけなら直接転送、複数人で共有したいときは Diamond Cloud セッションを使います。**

従来のクラウドドライブではありません。同じ Wi-Fi 上の近くの端末同士で、素早く、直接、制御しやすくファイルを共有するためのアプリです。

## 製品コンセプト

Diamond Transfer = ピアツーピア転送 + 任意で使える Diamond Cloud 共有セッション。

想定シーン：

- 家庭内の端末間で写真、動画、書類を共有
- 会議中に複数人からファイルを集める
- 教室やワークショップで資料を共有
- 撮影現場やスタジオで Mac / NAS / デスクトップをローカルの受け取り場所にする
- クラウドアカウントや外部インターネットを使わないローカル転送

## 機能一覧

| 機能 | 説明 |
| --- | --- |
| 近くの端末検出 | Bonjour/mDNS で同じ Wi-Fi 上の Diamond Transfer 端末を検出します。 |
| 直接転送 | LocalSend のような 1 対 1 の転送体験を保ちます。 |
| Diamond Cloud モード | 1 台の端末を共有セッション用のローカルサーバーにします。 |
| 二重の役割 | Diamond Cloud 端末は直接転送用 peer としても表示されます。 |
| 保存容量制限 | 利用可能なディスク容量を表示し、Diamond Cloud session の上限を設定できます。 |
| Diamond Cloud フォルダ | Diamond Cloud ファイルはホストが選んだローカルフォルダに保存されます。 |
| 一回限りのファイル | 表示対象を選び、対象端末が全員開いたら Diamond Cloud から削除します。 |
| macOS メニューバー | メインウィンドウを閉じると Dock アイコンは隠れ、メニューバー項目は残ります。 |
| ネイティブ UI | 現在のプロトタイプは SwiftUI の macOS アプリです。 |

## ピアツーピア転送

各アプリはローカルネットワーク上に peer ノードを公開します。他の端末はそのノードを検出し、直接転送先として選択できます。

向いている例：

- Mac から iPhone
- Android から Mac
- ノート PC 同士のファイル転送

## Diamond Cloud モード

任意の端末が Diamond Cloud モードを開始できます。Diamond Cloud モード中、その端末は 2 つの役割を持ちます：

- **Peer**：直接転送先として引き続き検出可能
- **Diamond Cloud host**：共有セッションのローカルサーバー

他の端末には以下の 2 種類が表示されます：

- **Nearby Devices**
- **Diamond Cloud**

## Diamond Cloud の保存容量管理

Diamond Cloud を開始する前に、ホストは次の項目を確認・設定できます：

- 利用可能なディスク容量
- Diamond Cloud の保存先フォルダ
- このセッションで利用できる最大容量

これにより、Diamond Cloud がローカルディスクを無制限に消費することを防ぎます。

## 一回限りのファイル

送信者はアップロード前にファイルを「一回限りのファイル」として指定できます。

ルール：

- 送信者は Diamond Cloud 内のどの端末に表示するかを選択
- 選択された端末だけがファイル一覧で確認可能
- ファイルには赤字で「一次性文件」と表示
- 各対象端末が開いたことを Diamond Cloud が記録
- 対象端末が全員開いた後、Diamond Cloud から自動削除
- 後から参加した端末には過去の一回限りファイルは自動表示されない

これは Diamond Cloud 上の保存ルールであり、DRM ではありません。スクリーンショット、外部撮影、閲覧後のコピーを完全に防ぐものではありません。

## 現在のプロトタイプ

現在の macOS demo は、実際の LAN 検出と広告を実装しています：

- `Network.framework` と Bonjour/mDNS
- サービス種別：`_diamondtransfer._tcp`
- 常時公開される peer ノード
- Diamond Cloud モード開始時に追加される Diamond Cloud ノード
- 1 台の Mac が直接 peer と Diamond Cloud host の両方として表示可能

ファイル本体の転送はまだ UI 上のシミュレーションです。次のステップは、実際の TCP 制御チャネルとストリーミング転送です。

## 技術キーワード

LAN file sharing, Wi-Fi file transfer, LocalSend alternative, AirDrop alternative, peer-to-peer transfer, Diamond Cloud session, Bonjour, mDNS, Network.framework, one-time files, private local cloud, local-first file transfer.

---
name: file-invoices
description: "このスキルは、ユーザーが「請求書を整理して」「請求書をDriveにアップして」「今月の請求書をファイリングして」と依頼した際に使用。Gmailから請求書メールを検索し、添付PDFをダウンロード、命名規則に従ってリネームし、Google Driveの税理士共有フォルダへアップロードする。"
args:
  - name: period
    description: "対象期間（例: '2月分', '2026-02', '先月'）。省略時は前月分。"
    required: false
  - name: account
    description: "Googleアカウント（デフォルト: hiro@a42x.co.jp）"
    required: false
allowed-tools: Bash, mcp__claude_ai_Gmail__gmail_search_messages, mcp__claude_ai_Gmail__gmail_read_message
version: "1.0.0"
---

# 請求書ファイリング自動化スキル

Gmailから請求書関連メールを検索し、添付PDFをダウンロードしてGoogle Driveの税理士共有フォルダへ整理する。

## 設定

| 項目 | 値 |
|------|-----|
| Google アカウント | `$ARGUMENTS.account` (デフォルト: `hiro@a42x.co.jp`) |
| Drive ルートフォルダID | `13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu` |
| 一時ディレクトリ | `/tmp/invoices-filing/` |
| gogcli パス | `/opt/homebrew/bin/gog` |
| 環境変数 | `GOG_KEYRING_PASSWORD=gogcli-keyring` |

## ファイル命名規則

```
YYYYMM_取引先名[_詳細].pdf
```

- `YYYYMM`: 請求対象の年月（例: 202602 = 2026年2月分）
- `取引先名`: 短縮名（下記マッピング参照）
- `詳細`: 必要に応じて補足（請求書番号等）

### 取引先名マッピング（既知）

| メール送信元キーワード | 短縮名 |
|----------------------|--------|
| ポケットサイン | ポケットサイン |
| FINOLAB | FINOLAB家賃 |
| SecureNavi, secure-navi | securenavi |
| PR TIMES, prtimes | PRTIMES |
| UPSIDER, mfkessai | UPSIDER |
| Google Payments (Cloud Platform, 01C800) | GCP-01C800 |
| Google Payments (Cloud Platform, 01A116) | GCP-01A116 |
| Google Payments (Workspace) | GoogleWorkspace |
| Slack | Slack |
| AGI Creative Labo, 上野 | 上野 |
| 津田匠貴 | 津田 |
| オオゼキ商店, 大関 | 大関孝之 |
| 中央総合法律事務所 藤下 | 中央総合法律事務所_藤下 |
| 中央総合法律事務所 脇 | 中央総合法律事務所_脇 |
| GMOサイバーセキュリティ, イエラエ | GMO |
| IVRy | IVRy |
| スマートラウンド | スマートラウンド |
| Blacksmith Software | Blacksmith |
| Alchemy | Alchemy |
| Cosense, Helpfeel | Cosense |
| Figma | Figma |
| mixer | mixer |
| 篠原 | 篠原 |
| 冨田, 富田 | 富田 |
| レバテック | レバテック |
| 水地, kazuakimizuchi | 水地 |
| アプリム | アプリム |
| 岡本, okamoto | okamoto |
| GCERTI | GCERTI |
| Bill One + 弁護士法人 | 中央総合法律事務所 |
| 住信SBI, netbk | 住信SBI |

新しい取引先が見つかった場合は、既存パターンに倣って短縮名を決定し、ユーザーに確認する。

## Drive フォルダ構造

```
税理士共有フォルダ (13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu)
├── 2026.3月/  ← 2月分の請求書はここ（処理月）
├── 2026.2月/  ← 1月分の請求書はここ
├── ...
```

**重要**: フォルダ名は `YYYY.M月`（例: `2026.3月`）。請求対象月の**翌月**のフォルダに格納する。
- 2月分の請求書 → `2026.3月` フォルダ
- 3月分の請求書 → `2026.4月` フォルダ

## 実行フロー

### Step 1: 対象期間の決定

`$ARGUMENTS.period` を解析し、対象の請求月と検索日付範囲を決定する。
- 「2月分」→ 請求月: 2026-02, 検索範囲: 2/20〜3/15頃
- 「先月」→ 前月を計算
- 省略時 → 前月

### Step 2: Gmail検索（Anthropic Gmail MCP使用）

以下のクエリで並行検索:
```
請求書 after:YYYY/M/20 before:YYYY/M+1/15
invoice after:YYYY/M/20 before:YYYY/M+1/15
(ご請求 OR お支払い OR 御請求 OR 領収書) after:YYYY/M/20 before:YYYY/M+1/15
```

### Step 3: 請求書メールの特定

検索結果から**実際の請求書メール**をフィルタリング:
- 含める: 請求書添付メール、請求書ダウンロードURL付きメール、領収書メール
- 除外する: プロモーション、ニュースレター、セミナー案内、マネーフォワードクラウドの広告メール、MFクラウド債務支払の通知（これは通知であり請求書本体ではない）

各メールの詳細を `mcp__claude_ai_Gmail__gmail_read_message` で確認し、添付ファイル情報とダウンロードURLを抽出する。

### Step 4: Drive上の既存ファイル確認

```bash
export GOG_KEYRING_PASSWORD="gogcli-keyring"
gog drive ls --parent <対象フォルダID> -a <account> --max 100
```

既にアップロード済みのファイルを特定し、重複を避ける。

### Step 5: 添付PDF付きメールの処理

gogcli で添付ファイルをダウンロード:

```bash
# メッセージの添付ファイル情報を取得
gog gmail get <messageId> -a <account> --json --results-only

# 添付ファイルをダウンロード
gog gmail attachment <messageId> <attachmentId> -a <account> --out /tmp/invoices-filing/ --name "YYYYMM_取引先名_詳細.pdf"
```

**注意**: gogcli の Gmail アカウントは請求書が届いているアカウントを使う。
- `hiro@a42x.co.jp` 宛のメール → `-a hiro@a42x.co.jp`
- `info@a42x.co.jp` 宛のメール → `-a hiro@a42x.co.jp`（同一アカウント）
- `hiro@mynawallet.co.jp` 宛 → `-a hiro@a42x.co.jp`（同一ユーザーで参照可能か確認）

### Step 6: Google Driveへアップロード

```bash
# 対象フォルダを特定（なければ作成）
gog drive ls --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account> --max 50

# フォルダがなければ作成
gog drive mkdir "YYYY.M月" --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account>

# アップロード
gog drive upload /tmp/invoices-filing/YYYYMM_取引先名.pdf --parent <フォルダID> --name "YYYYMM_取引先名_詳細.pdf" -a <account>
```

### Step 7: URL型請求書の報告

ダウンロードURLが記載されているメール（MF請求書、Bill One、PR TIMES、freee等）は自動ダウンロードできないため、一覧表として報告する:

```markdown
## 手動ダウンロードが必要な請求書

| 取引先 | ダウンロードURL | 提案ファイル名 | 期限 |
|--------|----------------|---------------|------|
| FINOLAB | https://invoice.moneyforward.com/... | 202602_FINOLAB家賃.pdf | 50日 |
```

### Step 8: 結果レポート

```markdown
## 請求書ファイリング完了レポート

### アップロード済み
| # | ファイル名 | 格納先フォルダ |
|---|-----------|--------------|
| 1 | 202602_ポケットサイン_請求書.pdf | 2026.3月 |

### 手動ダウンロード必要
| # | 取引先 | URL | 提案ファイル名 |
|---|--------|-----|---------------|

### スキップ（既にアップロード済み）
| # | ファイル名 |
|---|-----------|
```

## 注意事項

- **アップロード前に必ずユーザーの承認を得ること**: ファイル名と格納先フォルダの一覧を提示し、承認後にアップロードを実行する
- **gogcli の全コマンドに `export GOG_KEYRING_PASSWORD="gogcli-keyring"` を付与**すること
- 添付ファイルの attachment ID を取得するには、`gog gmail get <messageId> --json --results-only` でメッセージ詳細を取得し、`parts` 内の attachment 情報を参照する
- 一時ファイルは処理完了後に `rm -rf /tmp/invoices-filing/` でクリーンアップする
- `hiro@mynawallet.co.jp` 宛のメールの添付ファイルは、gogcli ではアクセスできない可能性がある。その場合は Anthropic Gmail MCP 経由で確認した旨を報告し、手動ダウンロードリストに追加する

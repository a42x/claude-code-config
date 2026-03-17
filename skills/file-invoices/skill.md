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
version: "2.0.0"
---

# 請求書ファイリング自動化スキル

Gmailから請求書関連メールを検索し、添付PDFをダウンロードしてGoogle Driveの税理士共有フォルダへ整理する。URL型請求書はブラウザで半自動ダウンロード。自動引き落としベンダーも含め**全件アップロード**する。

## 設定

| 項目 | 値 |
|------|-----|
| Google アカウント | `$ARGUMENTS.account` (デフォルト: `hiro@a42x.co.jp`) |
| Drive ルートフォルダID | `13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu` |
| 一時ディレクトリ | `/tmp/invoices-filing/` |
| gogcli パス | `/opt/homebrew/bin/gog` |
| 環境変数 | `GOG_KEYRING_PASSWORD=gogcli-keyring` |
| Config ファイル | skill ディレクトリ内の `config.json`（なければ分類なしで全件処理） |

## Config ファイル

`config.json` は skill ディレクトリ（`~/.claude/skills/file-invoices/config.json`）に配置。
`config.example.json` をコピーして作成する。

```json
{
  "auto_debit_vendors": [
    {
      "short_name": "GCP-01C800",
      "match_keywords": ["Google Payments", "Cloud Platform", "01C800"],
      "note": "クレカ自動引き落とし"
    }
  ],
  "url_download_watch_dir": "~/Downloads",
  "url_download_timeout_seconds": 120
}
```

- `auto_debit_vendors`: 自動引き落としベンダーの分類リスト。**処理はスキップしない**（全件アップロード）。レポートでの分類表示に使用。
- `match_keywords`: 取引先マッピングのキーワードと照合（メール送信元・件名に含まれるか）
- `url_download_watch_dir`: URL型請求書ダウンロード時の監視ディレクトリ
- `url_download_timeout_seconds`: ユーザーのダウンロード完了待ちタイムアウト

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
| povo | povo |

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

### Step 3.5: Auto-debit 分類

config.json を読み込む（存在しない場合はスキップ）:

```bash
CONFIG_PATH="$(dirname "$(readlink -f ~/.claude/skills/file-invoices/skill.md)")/config.json"
if [ -f "$CONFIG_PATH" ]; then
  cat "$CONFIG_PATH"
fi
```

各請求書メールの取引先を `auto_debit_vendors[].match_keywords` と照合し、マッチしたものに `is_auto_debit` フラグを付与する。

**処理フローは変更しない**: auto-debit であっても通常通りダウンロード・アップロードを実行する。フラグは Step 8 のレポート分類にのみ使用。

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

### Step 6: Google Driveへアップロード（添付PDF分）

```bash
# 対象フォルダを特定（なければ作成）
gog drive ls --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account> --max 50

# フォルダがなければ作成
gog drive mkdir "YYYY.M月" --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account>

# アップロード
gog drive upload /tmp/invoices-filing/YYYYMM_取引先名.pdf --parent <フォルダID> --name "YYYYMM_取引先名_詳細.pdf" -a <account>
```

### Step 7: URL型請求書の半自動ダウンロード

URL型の請求書（MF請求書、Bill One、freee、PR TIMES Box、住信SBI等）は認証が必要なため、ブラウザ経由で半自動処理する。

#### 7.1: Downloads フォルダの事前スナップショット

```bash
ls -1t ~/Downloads/*.pdf 2>/dev/null > /tmp/invoices-filing/downloads-before.txt
```

config.json の `url_download_watch_dir` が指定されている場合はそのパスを使用。

#### 7.2: URL一覧を提示し、ブラウザで一括オープン

ユーザーに以下のような一覧を提示:

```markdown
以下のURLをブラウザで開きます。各タブでPDFをダウンロードしてください。

| # | 取引先 | 提案ファイル名 | 自動引落 |
|---|--------|---------------|---------|
| 1 | FINOLAB | 202602_FINOLAB家賃.pdf | |
| 2 | 津田 | 202602_津田.pdf | |
| 3 | 住信SBI | 202602_住信SBI_振込手数料.pdf | ✓ |
```

承認後、`open` コマンドで一括オープン:

```bash
open "https://invoice.moneyforward.com/..."
open "https://app.bill-one.com/..."
# 各URLを順次開く
```

#### 7.3: ユーザーの完了待ち

「ダウンロードが完了したら教えてください」と案内し、ユーザーの入力を待つ。

#### 7.4: Downloads フォルダの差分検出

```bash
ls -1t ~/Downloads/*.pdf 2>/dev/null > /tmp/invoices-filing/downloads-after.txt

# 差分（新しく追加された PDF ファイル）を検出
comm -13 <(sort /tmp/invoices-filing/downloads-before.txt) <(sort /tmp/invoices-filing/downloads-after.txt)
```

#### 7.5: ダウンロードされた PDF のマッチング

新しいPDFファイルが見つかった場合、取引先を推定する:

1. **ファイル名キーワード照合**: ダウンロードされたPDFのファイル名に取引先名マッピングのキーワードが含まれるか
2. **ダウンロード時刻順**: open コマンドの実行順序との対応
3. **推定不能時**: ユーザーに確認

推定結果をユーザーに提示して確認:

```markdown
以下のマッチングで正しいですか？

| ダウンロードされたファイル | → | リネーム後 |
|--------------------------|---|-----------|
| C-202603000070.pdf | → | 202603_FINOLAB家賃.pdf |
| invoice_202602.pdf | → | 202602_津田.pdf |
```

#### 7.6: リネーム → アップロード

確認後、リネームして Drive にアップロード:

```bash
cp ~/Downloads/<detected_file>.pdf /tmp/invoices-filing/YYYYMM_取引先名.pdf
gog drive upload /tmp/invoices-filing/YYYYMM_取引先名.pdf --parent <フォルダID> --name "YYYYMM_取引先名.pdf" -a <account>
```

#### 7.7: 未取得分の報告

マッチしなかった、またはダウンロードされなかった請求書を報告する。

### Step 8: 結果レポート

```markdown
## 請求書ファイリング完了レポート

### アップロード済み（添付PDF）
| # | ファイル名 | 格納先 | 自動引落 |
|---|-----------|--------|---------|
| 1 | 202602_ポケットサイン_請求書.pdf | 2026.3月 | |
| 2 | 202602_GCP-01C800_請求書.pdf | 2026.3月 | ✓ |

### アップロード済み（URLダウンロード経由）
| # | ファイル名 | 格納先 | 自動引落 |
|---|-----------|--------|---------|
| 1 | 202602_FINOLAB家賃.pdf | 2026.3月 | |

### 手動対応必要（未取得）
| # | 取引先 | URL | 提案ファイル名 |
|---|--------|-----|---------------|

### スキップ（既にアップロード済み）
| # | ファイル名 |
|---|-----------|
```

### Step 9: クリーンアップ

```bash
rm -rf /tmp/invoices-filing/
```

## 注意事項

- **アップロード前に必ずユーザーの承認を得ること**: ファイル名と格納先フォルダの一覧を提示し、承認後にアップロードを実行する
- **gogcli の全コマンドに `export GOG_KEYRING_PASSWORD="gogcli-keyring"` を付与**すること
- 添付ファイルの attachment ID を取得するには、`gog gmail get <messageId> --json --results-only` でメッセージ詳細を取得し、`parts` 内の attachment 情報を参照する
- 一時ファイルは処理完了後に `rm -rf /tmp/invoices-filing/` でクリーンアップする
- `hiro@mynawallet.co.jp` 宛のメールの添付ファイルは、gogcli ではアクセスできない可能性がある。その場合は Anthropic Gmail MCP 経由で確認した旨を報告し、手動ダウンロードリストに追加する
- **全請求書をアップロードする**: auto-debit ベンダーも含めて全件 Drive にアップロードする。auto-debit フラグはレポートの分類表示にのみ使用する
- config.json が存在しない場合は auto-debit 分類をスキップし、v1 と同じ動作をする

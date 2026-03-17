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
allowed-tools: Bash, Read, mcp__claude_ai_Gmail__gmail_search_messages, mcp__claude_ai_Gmail__gmail_read_message, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_type, mcp__playwright__browser_wait_for, mcp__playwright__browser_wait_for_network_idle, mcp__playwright__browser_file_upload, mcp__playwright__browser_press_key, mcp__playwright__browser_select_option, mcp__playwright__browser_close
version: "3.0.0"
---

# 請求書ファイリング自動化スキル

Gmailから請求書関連メールを検索し、添付PDFをダウンロードしてGoogle Driveの税理士共有フォルダへ整理する。URL型請求書は Playwright MCP で自動ダウンロード。HTML-only 領収書はスクリーンショットで対応。自動引き落としベンダーも含め**全件アップロード**する。

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

### 主要フィールド

- `auto_debit_vendors`: 自動引き落としベンダーの分類リスト。**処理はスキップしない**（全件アップロード）。レポートでの分類表示に使用。
  - `conditional`: `true` の場合、請求金額・内容により自動引き落とし/振込が変わる。Step 3.5 で金額チェックが必要。
- `html_only_vendors`: PDF添付なし・ダウンロードURLなしのベンダー。メール本文のスクリーンショットでキャプチャする。
- `gmail_platform_searches`: Step 2-A で使用するプラットフォーム固有の Gmail 検索クエリ。
- `playwright_download_dir`: Playwright MCP がファイルをダウンロードするディレクトリ（デフォルト: `.playwright-mcp/`）
- `fallback_download_dir`: フォールバック時（手動ダウンロード）の監視ディレクトリ（デフォルト: `~/Downloads`）
- `url_platform_hints`: プラットフォームごとのダウンロード挙動ヒント。
  - `download_format`: ダウンロード形式（`pdf` | `zip`）。`zip` の場合は展開が必要。

## ファイル命名規則

```
[AD_]YYYYMM_取引先名[_詳細].pdf
```

- `AD_`: **自動引き落としプレフィックス**（Auto Debit）。手動振込が不要な請求書に付与する。
  - `AD_` あり → 振込不要（クレカ自動・口座振替等）
  - `AD_` なし → **要振込**
  - config.json の `auto_debit_vendors` にマッチしたベンダーに付与
  - `conditional: true` のベンダーは金額・内容で判定（条件を満たす場合のみ `AD_` 付与）
- `YYYYMM`: **請求対象（サービス提供）の年月**。メール受信日ではない。
  - 例: 1月分のサービス利用料が2月に届いた場合 → `202601`
  - 判定方法: 請求書本文の「ご利用期間」「対象月」「XX月分」を確認する
  - 判定できない場合: メール・PDFに期間記載がなければ、受信月の前月を仮設定し、レポートで `⚠ 要確認` を付与
- `取引先名`: 短縮名（下記マッピング参照）
- `詳細`: 必要に応じて補足（請求書番号等）
- HTML-only 領収書の場合は拡張子 `.png`

### 命名規則の例

```
AD_202602_GCP-01C800_請求書.pdf              ← 自動引落（振込不要）
AD_202602_Slack_領収書.pdf                   ← 自動引落（振込不要）
AD_202602_中央総合法律事務所_藤下_顧問料.pdf    ← 条件付き→¥55,000は自動引落
202602_津田.pdf                              ← 要振込
202602_上野.pdf                              ← 要振込
202601_中央総合法律事務所_脇_法律相談手数料.pdf  ← 条件付き→超過分は要振込
AD_202602_Figma_領収書.png                   ← 自動引落（HTMLスクショ）
```

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
| 中央総合法律事務所 | 中央総合法律事務所_[送付者姓] |
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
| 住信SBI, netbk | 住信SBI |
| povo | povo |

新しい取引先が見つかった場合は、既存パターンに倣って短縮名を決定し、ユーザーに確認する。

### 条件付き auto-debit ベンダー

config.json で `"conditional": true` のベンダーは、請求金額・内容で自動引き落とし/振込が変わる。

| ベンダー | 自動引き落とし条件 | 振込が必要なケース |
|---------|------------------|------------------|
| 中央総合法律事務所 | ¥55,000 の月額顧問料 | 超過分（法律相談手数料等、金額が ¥55,000 以外） |

**Bill One 経由の請求書は送付者の名前が毎回異なる可能性がある**（藤下、脇、金澤、谷 等）。ファイル名は `YYYYMM_中央総合法律事務所_[送付者姓]_[内容].pdf` とする。

### HTML-only 領収書ベンダー

PDF添付もダウンロードURLもなく、メール本文が領収書となるベンダー。

| ベンダー | 送信元 | 対応方法 |
|---------|--------|---------|
| Figma | figma.com | メール本文HTMLをレンダリングしてスクリーンショット（.png） |

### 既存ファイルのリネーム対応

Drive フォルダ内に命名規則に従っていないファイル（スキル導入前の手動アップロード分）が存在する場合:

1. Step 4 の既存ファイル確認時に、命名規則に合致しないファイルを検出する
2. 既知の取引先名マッピングに基づいて正しいファイル名を推定する
3. レポートの末尾に「リネーム候補」セクションとして一覧表示する
4. ユーザーの承認後に `gog drive rename <fileId> "<新ファイル名>"` で一括リネーム

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

### Step 2: Gmail検索（2段階・Anthropic Gmail MCP使用）

Gmail MCP の検索結果は最大50件のため、**2段階検索**で漏れを防止する。

#### 2-A: プラットフォーム固有検索（高精度・漏れ防止）

config.json の `gmail_platform_searches` に定義されたクエリに日付範囲を付与して**並行実行**:

```
from:no-reply@bill-one.com after:YYYY/M/20 before:YYYY/M+1/15
from:figma.com after:YYYY/M/20 before:YYYY/M+1/15
from:do_not_reply@moneyforward.com after:YYYY/M/20 before:YYYY/M+1/15
from:payments-noreply@google.com after:YYYY/M/20 before:YYYY/M+1/15
from:feedback@slack.com (invoice OR receipt OR 領収書 OR プラン) after:YYYY/M/20 before:YYYY/M+1/15
from:bill@prtimes.co.jp after:YYYY/M/20 before:YYYY/M+1/15
from:noreply@mfkessai.co.jp after:YYYY/M/20 before:YYYY/M+1/15
from:no-reply@doc-issue.layerx.jp after:YYYY/M/20 before:YYYY/M+1/15
from:stripe.com (領収書 OR receipt OR invoice) after:YYYY/M/20 before:YYYY/M+1/15
```

#### 2-B: 汎用キーワード検索（補完）

個人ベンダー等をカバー:

```
(請求書 OR 御請求書) has:attachment after:YYYY/M/20 before:YYYY/M+1/15
(invoice OR receipt) has:attachment after:YYYY/M/20 before:YYYY/M+1/15
(ご請求 OR お支払い OR 領収書) after:YYYY/M/20 before:YYYY/M+1/15
```

**注意**: `has:attachment` を付けて結果を絞り込み、50件制限への到達を軽減する。

#### 2-C: 重複排除

2-A と 2-B の結果を messageId で重複排除し、統合リストを作成する。

### Step 3: 請求書メールの特定

検索結果から**実際の請求書メール**をフィルタリング:
- 含める: 請求書添付メール、請求書ダウンロードURL付きメール、領収書メール、HTML-only 領収書メール
- 除外する: プロモーション、ニュースレター、セミナー案内、マネーフォワードクラウドの広告メール、MFクラウド債務支払の通知（これは通知であり請求書本体ではない）

各メールの詳細を `mcp__claude_ai_Gmail__gmail_read_message` で確認し、以下を抽出する:
- 添付ファイル情報（attachment ID, ファイル名, MIME type）
- ダウンロードURL（メール本文内のリンク）
- **請求対象期間**: メール本文から「ご利用期間」「対象月」「XX月分」等を探し、YYYYMM を決定する
  - 例: 「2026年1月ご利用分」→ 202601
  - メール本文に記載がない場合は、添付PDFダウンロード後に確認する（Step 5 で再判定）

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

#### Conditional auto-debit の処理

`conditional: true` のベンダーについては追加判定を行う:

1. 請求書の金額をメール本文または添付PDFから抽出する
2. config.json の `note` フィールドに記載された条件と照合する
   - 例: 中央総合法律事務所 — 金額が ¥55,000 → `is_auto_debit = true`（顧問料）
   - 金額が ¥55,000 以外 → `is_auto_debit = false`（振込が必要）
3. レポートでは `⚠ 条件付き` マークで表示し、判定根拠（金額）を付記する

#### HTML-only ベンダーの分類

config.json の `html_only_vendors` と照合し、マッチしたものに `is_html_only` フラグを付与する。Step 7 で通常のダウンロードではなくスクリーンショット処理を行う。

### Step 4: Drive上の既存ファイル確認

```bash
export GOG_KEYRING_PASSWORD="gogcli-keyring"
gog drive ls --parent <対象フォルダID> -a <account> --max 100
```

既にアップロード済みのファイルを特定し、重複を避ける。

**命名規則不一致の既存ファイルも検出**し、リネーム候補としてレポートに含める。

### Step 5: 添付PDF付きメールの処理

gogcli で添付ファイルをダウンロード:

```bash
# メッセージの添付ファイル情報を取得
gog gmail get <messageId> -a <account> --json --results-only

# 添付ファイルをダウンロード
gog gmail attachment <messageId> <attachmentId> -a <account> --out /tmp/invoices-filing/ --name "YYYYMM_取引先名_詳細.pdf"
```

**YYYYMM の再判定**: ダウンロードしたPDFの内容（Read ツール等）で請求対象期間を確認する。メール本文の情報と一致しない場合はPDF内の記載を優先する。

**注意**: gogcli の Gmail アカウントは請求書が届いているアカウントを使う。
- `hiro@a42x.co.jp` 宛のメール → `-a hiro@a42x.co.jp`
- `info@a42x.co.jp` 宛のメール → `-a hiro@a42x.co.jp`（同一アカウント）
- `hiro@mynawallet.co.jp` 宛 → `-a hiro@a42x.co.jp`（同一ユーザーで参照可能）

### Step 6: Google Driveへアップロード（添付PDF分）

```bash
# 対象フォルダを特定（なければ作成）
gog drive ls --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account> --max 50

# フォルダがなければ作成
gog drive mkdir "YYYY.M月" --parent 13y2jsuP6MjL27RLuZZp7YKmjMw4C5VGu -a <account>

# アップロード
gog drive upload /tmp/invoices-filing/YYYYMM_取引先名.pdf --parent <フォルダID> --name "YYYYMM_取引先名_詳細.pdf" -a <account>
```

### Step 7: URL型請求書の自動ダウンロード（Playwright MCP）

URL型の請求書（MF請求書、Bill One、freee、PR TIMES Box等）は Playwright MCP でブラウザ自動操作してダウンロードする。

**前提**: Playwright MCP が `allowed-tools` に含まれていること。MCP が利用不可の場合は Step 7F（フォールバック）へ。

**Playwright のダウンロードディレクトリは `.playwright-mcp/`**（カレントディレクトリ配下）。`~/Downloads` ではない。

#### 7.1: 事前スナップショット + URL一覧提示

```bash
mkdir -p /tmp/invoices-filing
ls -1t .playwright-mcp/* 2>/dev/null > /tmp/invoices-filing/downloads-before.txt
```

URL一覧をユーザーに提示し承認を得る。

#### 7.2: 各プラットフォームでの自動ダウンロード

URL型請求書を1件ずつ処理する。各プラットフォームごとに操作手順が異なる:

##### MoneyForward 請求書 (`invoice.moneyforward.com`)
1. `browser_navigate` でURLを開く
2. `browser_snapshot` でページ構造を確認
3. ログイン画面が表示された場合 → ユーザーに案内し、ログイン完了を待つ
4. 「請求書」ダウンロードボタンを `browser_click` で押下
5. ダウンロード完了を待つ

##### Bill One (`app.bill-one.com`)

**注意**: Bill One の「Download all」は**ZIPファイル**をダウンロードする（PDFではない）。

1. `browser_navigate` でURLを開く
2. `browser_snapshot` でページ構造を確認
3. 「Download all」ボタンを `browser_click`
4. ダウンロード完了を待つ
5. **ZIP展開**:
   ```bash
   unzip .playwright-mcp/invoices_*.zip -d /tmp/invoices-filing/billone-extracted/
   ls /tmp/invoices-filing/billone-extracted/**/*.pdf
   ```
6. 展開された各PDFの内容を確認し、取引先名・請求対象月を特定してリネームする

##### freee (`invoice.secure.freee.co.jp`)
1. `browser_navigate` でURLを開く
2. `browser_snapshot` でページ構造を確認
3. PDFダウンロードボタンを `browser_click`
4. ダウンロード完了を待つ

##### PR TIMES Box (`prtimes.box.com`)
1. `browser_navigate` でURLを開く
2. パスワード入力が必要な場合 → 別メールのパスワードを `browser_type` で入力
3. ダウンロードボタンを `browser_click`
4. ダウンロード完了を待つ

##### HTML-only 領収書（Figma 等）

PDF添付もダウンロードURLもないサービスの対応。

1. `mcp__claude_ai_Gmail__gmail_read_message` でメール本文を取得
2. gogcli でメッセージの HTML パートを取得:
   ```bash
   gog gmail get <messageId> -a <account> --json 2>&1 > /tmp/invoices-filing/email.json
   # Python で HTML パートを base64 デコードしてファイルに保存
   ```
3. ローカル HTTP サーバーで HTML を配信:
   ```bash
   cd /tmp && python3 -m http.server 8765 &
   ```
4. `browser_navigate` で `http://localhost:8765/receipt.html` を開く
5. `browser_take_screenshot` でフルページスクリーンショットを撮影
6. スクリーンショットを `/tmp/invoices-filing/YYYYMM_取引先名_領収書.png` にリネーム
7. HTTP サーバーを停止

##### 汎用フロー（上記以外のプラットフォーム）
1. `browser_navigate` でURLを開く
2. `browser_snapshot` でページ構造を確認
3. PDFダウンロードに見えるリンク/ボタンを探して `browser_click`
4. うまくいかない場合はフォールバック（7F）へ

#### 7.3: ダウンロードファイルの回収

```bash
# Playwright ダウンロードディレクトリから新規ファイルを検出
ls -1t .playwright-mcp/* 2>/dev/null > /tmp/invoices-filing/downloads-after.txt
comm -13 <(sort /tmp/invoices-filing/downloads-before.txt) <(sort /tmp/invoices-filing/downloads-after.txt)
```

**ZIP ファイルの自動展開**: 検出されたファイルが `.zip` の場合は展開してPDFを取り出す:
```bash
unzip .playwright-mcp/<file>.zip -d /tmp/invoices-filing/zip-extracted/
```

#### 7.4: リネーム → アップロード

```bash
# Playwright MCP ダウンロードから回収
cp .playwright-mcp/<detected_file>.pdf /tmp/invoices-filing/YYYYMM_取引先名.pdf
gog drive upload /tmp/invoices-filing/YYYYMM_取引先名.pdf --parent <フォルダID> --name "YYYYMM_取引先名.pdf" -a <account>
```

#### 7.5: ブラウザを閉じる

全URLの処理完了後:
```
browser_close
```

#### 7F: フォールバック（Playwright 利用不可時）

Playwright MCP が利用できない場合、または特定のURLで自動操作に失敗した場合:

1. `open` コマンドでURLをブラウザに開く
2. ユーザーに手動ダウンロードを依頼
3. `~/Downloads` の差分検出で新規PDFを特定（**手動ブラウザ操作時は `~/Downloads` が正しい**）
4. リネーム → アップロード

```bash
open "https://invoice.moneyforward.com/..."
# ユーザーの完了入力を待つ
```

### Step 8: 結果レポート

```markdown
## 請求書ファイリング完了レポート

### アップロード済み（添付PDF）
| # | ファイル名 | 格納先 | 自動引落 | YYYYMM根拠 |

### アップロード済み（URLダウンロード経由）
| # | ファイル名 | 格納先 | 自動引落 | DL形式 |

### アップロード済み（HTMLスクリーンショット）
| # | ファイル名 | 格納先 | 自動引落 | 備考 |

### 条件付き自動引落の判定結果
| # | ベンダー | 金額 | 判定 | 理由 |

### YYYYMM 要確認
| # | ファイル名 | 仮設定 | 理由 |

### リネーム候補（命名規則不一致の既存ファイル）
| # | 現在のファイル名 | 提案リネーム | Drive ID |

### 手動対応必要（未取得）
| # | 取引先 | URL/理由 | 提案ファイル名 |

### スキップ（既にアップロード済み）
| # | ファイル名 |
```

### Step 9: クリーンアップ

```bash
rm -rf /tmp/invoices-filing/
# Playwright のダウンロードファイルも削除
rm -f .playwright-mcp/*.pdf .playwright-mcp/*.zip
# ローカル HTTP サーバーが残っていれば停止
kill $(lsof -ti:8765) 2>/dev/null || true
```

## 注意事項

- **アップロード前に必ずユーザーの承認を得ること**: ファイル名と格納先フォルダの一覧を提示し、承認後にアップロードを実行する
- **gogcli の全コマンドに `export GOG_KEYRING_PASSWORD="gogcli-keyring"` を付与**すること
- 添付ファイルの attachment ID を取得するには、`gog gmail get <messageId> --json --results-only` でメッセージ詳細を取得する
- 一時ファイルは処理完了後にクリーンアップする
- **全請求書をアップロードする**: auto-debit ベンダーも含めて全件 Drive にアップロードする。auto-debit フラグはレポートの分類表示にのみ使用する
- config.json が存在しない場合は分類をスキップし、v1 と同じ動作をする
- **Playwright のダウンロードディレクトリは `.playwright-mcp/`** であり、`~/Downloads` ではない。手動フォールバック時のみ `~/Downloads` を使用する
- **ZIPファイルの展開**: Bill One 等、ZIP でダウンロードされるプラットフォームがある。ダウンロード後にファイル拡張子を確認し、`.zip` の場合は `unzip` で展開する
- **HTML-only 領収書**: Figma 等、PDF添付もダウンロードURLもないサービスがある。メール本文をブラウザでレンダリングし、スクリーンショットを撮影してアップロードする
- **YYYYMM はメール受信日ではなく請求対象期間**: 必ず請求書本文で対象月を確認する。1月分が2月に届くケースが通常
- **Gmail 検索の50件制限**: 汎用検索だけでは全件取得できない。プラットフォーム固有の `from:` 検索を必ず並行実行する

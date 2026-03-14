---
name: gog-sheets
description: "このスキルは、ユーザーが「スプレッドシートを読んで」「シートを更新して」「行を追加して」「スプレッドシートを作成して」「シートをエクスポートして」と依頼した際に使用。gogcli経由でGoogle Sheetsを操作する。マルチアカウント対応。"
args:
  - name: action
    description: "Action to perform (e.g., read, update, append)"
    required: true
  - name: target
    description: "Spreadsheet ID or URL, and range (e.g., Sheet1!A1:C10)"
    required: false
allowed-tools: Bash
version: "1.0.0"
---

# Google Sheets via gogcli

Google Sheets operations use `gog sheets` CLI. Supports multi-account via `--account`.

## Accounts

Configure your accounts with `gog auth add <email>`. Use `-a <email>` to switch accounts.

## Extracting Spreadsheet ID from URL

From `https://docs.google.com/spreadsheets/d/SPREADSHEET_ID/edit` extract the `SPREADSHEET_ID` part.

## Common Commands

### Read values
```bash
gog sheets get SPREADSHEET_ID "Sheet1!A1:C10" -a user@example.com
```

### Get spreadsheet metadata (list tabs)
```bash
gog sheets metadata SPREADSHEET_ID -a user@example.com
```

### Update values
```bash
gog sheets update SPREADSHEET_ID "Sheet1!A1" "value1" "value2" -a user@example.com
```

### Append row
```bash
gog sheets append SPREADSHEET_ID "Sheet1!A:C" "val1" "val2" "val3" -a user@example.com
```

### Clear range
```bash
gog sheets clear SPREADSHEET_ID "Sheet1!A1:C10" -a user@example.com
```

### Export (xlsx/csv/pdf)
```bash
gog sheets export SPREADSHEET_ID -a user@example.com --format csv
```

### Create spreadsheet
```bash
gog sheets create "Title" -a user@example.com
```

### Find and replace
```bash
gog sheets find-replace SPREADSHEET_ID "find" "replace" -a user@example.com
```

## Instructions

1. Parse `$ARGUMENTS.action` to determine the operation
2. If `$ARGUMENTS.target` is a URL, extract the spreadsheet ID
3. Execute via `gog sheets` commands
4. Report results to user

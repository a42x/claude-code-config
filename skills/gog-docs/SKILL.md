---
name: gog-docs
description: "このスキルは、ユーザーが「Googleドキュメントを読んで」「ドキュメントをエクスポートして」「ドキュメントを作成して」「ドキュメントの内容を確認して」と依頼した際に使用。gogcli経由でGoogle Docsを操作する。マルチアカウント対応。"
args:
  - name: action
    description: "Action to perform (e.g., read doc, export, create)"
    required: true
  - name: target
    description: "Document ID or URL"
    required: false
allowed-tools: Bash
version: "1.0.0"
---

# Google Docs via gogcli

Google Docs operations use `gog docs` CLI. Supports multi-account via `--account`.

## Accounts

Configure your accounts with `gog auth add <email>`. Use `-a <email>` to switch accounts.

## Extracting Document ID from URL

From `https://docs.google.com/document/d/DOCUMENT_ID/edit` extract the `DOCUMENT_ID` part.

## Common Commands

### Read document as plain text
```bash
gog docs cat DOCUMENT_ID -a user@example.com
```

### Get document metadata
```bash
gog docs info DOCUMENT_ID -a user@example.com
```

### Export document (md/txt/pdf/docx)
```bash
gog docs export DOCUMENT_ID -a user@example.com --format md
```

### Create document
```bash
gog docs create "Title" -a user@example.com
```

### Write content to document
```bash
gog docs write DOCUMENT_ID -a user@example.com --content "text"
```

### Find and replace
```bash
gog docs edit DOCUMENT_ID "find" "replace" -a user@example.com
```

### Show document structure
```bash
gog docs structure DOCUMENT_ID -a user@example.com
```

## Instructions

1. Parse `$ARGUMENTS.action` to determine the operation
2. If `$ARGUMENTS.target` is a URL, extract the document ID
3. Execute via `gog docs` commands
4. Report results to user

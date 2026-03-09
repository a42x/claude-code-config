---
name: gws-sheets
description: Read and write Google Sheets using gws CLI. Preferred over browser automation.
---

# Google Sheets (gws CLI)

Use the `gws` command for Google Sheets access. Browser automation is a last resort.

## Commands

### List sheets

```bash
gws sheets spreadsheets get \
  --params '{"spreadsheetId": "<ID>", "fields": "sheets.properties.title"}'
```

### Read cells

```bash
gws sheets spreadsheets values get \
  --params '{"spreadsheetId": "<ID>", "range": "Sheet1!A1:Z50"}'
```

For non-ASCII sheet names, use escaped double quotes:

```bash
gws sheets spreadsheets values get \
  --params "{\"spreadsheetId\": \"<ID>\", \"range\": \"SheetName!A1:Z50\"}"
```

### Write cells

```bash
gws sheets spreadsheets values update \
  --params '{"spreadsheetId": "<ID>", "range": "Sheet1!A1", "valueInputOption": "USER_ENTERED"}' \
  --json '{"values": [["value1", "value2"], ["value3", "value4"]]}'
```

## Notes

- Include sheet name in `range` (e.g., `'Sheet1'!A1:Z50`)
- Non-ASCII sheet names require JSON escaping
- Output format: `--format table|csv|yaml`

---
name: security-check
description: "セキュリティ脆弱性チェック。Trigger: 脆弱性, CVE, セキュリティ, 安全性確認, 脆弱性チェック, 'vulnerability', 'CVE check', 'security advisory', 'is X secure'."
argument-hint: [package-or-library@version]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# セキュリティチェック

**$ARGUMENTS** の既知の脆弱性・セキュリティアドバイザリーを調査する。

## CRITICAL: Tool requirements

You MUST use Tavily MCP tools for ALL web research. Find and use the tools whose names contain "tavily":

- **Search** → tool name matches `*tavily*search*` — web queries
- **Extract** → tool name matches `*tavily*extract*` — pull content from specific URLs

Before doing any research, call `ToolSearch` with query `"+tavily"` to discover the exact tool names available in this session. Then use ONLY those tools.

**FORBIDDEN — Do NOT use these tools:**
- `WebSearch` — bypasses user's Tavily API key
- `WebFetch` — bypasses user's Tavily API key

If no Tavily MCP tools are found, **STOP immediately** and return an error message:
> "Tavily MCP tools are not available. Please verify the tavily MCP server is configured in settings.json."

Do NOT fall back to WebSearch or WebFetch under any circumstances.

## Language

Match the user's language. If the user writes in Japanese, return all sections in Japanese. Technical terms and proper nouns may remain in their original language.

## 引用形式

本文中で番号付き引用 `[1]`, `[2]` を使用し、すべての事実主張にソースを紐付ける。末尾の**ソース一覧**で全URLを一覧化する。

## 出力の充実度

- 各セクションは最低2–3段落の具体的内容を含める（箇条書きの羅列だけで終わらせない）
- ソースから得た具体的な数値・引用・事例を盛り込む
- 結論だけでなく、根拠となるデータ・文脈を十分に記述する
- 読者がソースをクリックせずとも内容を理解できる詳細度を目指す

## Tool budget

| Tool | Max calls | When to use |
|------|-----------|-------------|
| **search** | 5 | Domain-segmented vulnerability searches |
| **extract** | 2 | search snippet では CVE 詳細・CVSS が不十分な場合のみ |

## Token optimization

- `search_depth: "basic"`, `max_results: 3` をデフォルトで使用
- NVD/CVE の検索結果 snippet には CVSS スコア・影響バージョンが含まれることが多い — extract 前に確認
- 脆弱性が発見されなかった場合、残りの domain-segmented search をスキップ
- extract 時は `query` + `chunks_per_source: 3` で CVE 詳細のみ取得
- `include_raw_content` は使用しない（コンテキスト膨張を防ぐ）
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"）、そちらを優先する**

## Method

1. **Parse input** — extract package name, version (if provided), and ecosystem from $ARGUMENTS. If version is not specified, note "latest stable" assumption.
2. **Domain-segmented search** — execute searches in priority order:
   - **NVD/CVE databases**: `include_domains: ["nvd.nist.gov", "cve.org"]`, query: `$PACKAGE vulnerability CVE`
   - **GitHub Advisories**: `include_domains: ["github.com"]`, query: `$PACKAGE security advisory GHSA`, `time_range: "month"`
   - **Security aggregators**: `include_domains: ["security.snyk.io", "osv.dev"]`, query: `$PACKAGE vulnerability`
   - **General security news**: query: `$PACKAGE security vulnerability exploit`, `time_range: "month"`
3. **Extract CVE details** — for each discovered vulnerability, extract:
   - CVE/GHSA identifier
   - CVSS score (from official NVD/vendor source only)
   - Affected version range
   - Fix version
   - Exploit availability
4. **Version matching** — if user specified a version, filter results to applicable vulnerabilities only.
5. **Severity classification** — classify overall risk based on highest-severity finding.

## Severity levels

| Level | Criteria |
|-------|----------|
| `[Critical]` | CVSS 9.0–10.0, or actively exploited, or RCE without authentication |
| `[High]` | CVSS 7.0–8.9, or significant impact with known exploit |
| `[Medium]` | CVSS 4.0–6.9, or limited impact / requires specific conditions |
| `[Low]` | CVSS 0.1–3.9, or theoretical with no known exploit |
| `[No Known Issues]` | No vulnerabilities found in searched databases |

## 出力ファイル

最終レポートは Write ツールで `inbox/security-check-YYYY-MM-DD-[topic].md` に書き出す（YYYY-MM-DD は実行日、[topic] は調査トピックの短い英語記述）。ソース素材として inbox/ に入れることで、/pipeline の処理対象となる。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **セキュリティ概況** — overall severity level + 概況を2–3段落で記述する + `as of YYYY-MM-DD`. 本文中で `[1]`, `[2]` のインライン引用を使用する。
2. **脆弱性一覧** (if any found)

   | CVE/GHSA | 深刻度 | CVSS | 影響バージョン | 概要 | 修正バージョン | URL |
   |----------|--------|------|---------------|------|---------------|-----|

3. **詳細分析** — Critical/High の各脆弱性について、攻撃ベクトル・影響範囲・エクスプロイト状況を2–3段落で分析する。
4. **対策・推奨事項** — 優先度順の修正ステップ（アップグレードパス、ワークアラウンド、緩和策）を具体的に記述する。
5. **追加の懸念事項** — 依存関係の脆弱性、EOL状況、メンテナンス活動を記述する。
6. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## Guardrails

- **CVSSは公式値のみ** — use CVSS scores from NVD, vendor advisories, or GitHub. NEVER estimate or calculate CVSS scores.
- **バージョン未指定時** — check against latest stable version. State this assumption clearly.
- **0-day / パッチ済み / disputed の区別** — clearly label:
  - `[0-day]` — no patch available
  - `[パッチ済み]` — fix released
  - `[Disputed]` — vendor disputes the vulnerability
- **日付は必須** — all findings must include: `as of YYYY-MM-DD`
- **Exploit情報の取り扱い** — report existence of exploits but NEVER provide exploit code or detailed exploitation steps.
- **依存関係の注意** — if the package has known-vulnerable dependencies, mention them separately.
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Architecture-level security review → `/deep-research`
- Library documentation/migration → `/docs-dive`
- General web research → `/web-research`

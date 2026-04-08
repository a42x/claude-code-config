---
name: fact-check
description: "主張・情報のファクトチェック。Trigger: 事実確認, ファクトチェック, 本当?, 真偽確認, これは正しい?, 'is it true', 'verify', 'fact check'."
argument-hint: [claim-to-verify]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# ファクトチェック

**$ARGUMENTS** の真偽をクロスバリデーションで検証する。

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
| **search** | 4 | Claim verification, counter-evidence, fact-check sites |
| **extract** | 2 | search snippet では判定に不十分な場合のみ |

## Token optimization

- `search_depth: "basic"`, `max_results: 3` をデフォルトで使用（`"advanced"` は 2 倍のクレジット消費）
- ファクトチェックサイト（Snopes 等）は snippet に判定結果が含まれることが多い — extract 前に確認
- 反証検索は supporting evidence が弱い場合のみ実行
- extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"）、そちらを優先する**

## Method

1. **Restate the claim** — extract the core verifiable assertion(s) from $ARGUMENTS.
2. **Existing fact-checks** — search with:
   - `search_depth: "basic"`
   - `include_domains: ["snopes.com", "factcheck.org", "reuters.com/fact-check", "politifact.com", "apnews.com/ap-fact-check"]`
   - Use quoted phrases from the claim for precision
3. **Primary source search** — find the original source of the claim (first appearance, official statement, data).
4. **Counter-evidence search** — actively search for contradicting evidence:
   - Negate the claim in query (e.g., "X is NOT true", "X debunked")
   - Search for alternative explanations
5. **Cross-validate** — compare findings across sources. Check for:
   - Single-origin chains (multiple articles citing the same single source)
   - Circular reporting (Source A cites B which cites A)
6. **Extract** key pages only when search snippets are insufficient for judgment.
7. **Render verdict** based on evidence weight.

## Verdict scale

| Verdict | Criteria |
|---------|----------|
| `TRUE` | 2+ independent, credible sources confirm; no credible contradictions |
| `FALSE` | Credible evidence directly refutes; or original claim is fabricated |
| `PARTIALLY TRUE` | Core claim has merit but contains inaccuracies, exaggerations, or missing context |
| `UNVERIFIED` | Insufficient evidence to confirm or deny |

## 出力ファイル

最終レポートは Write ツールで `inbox/fact-check-YYYY-MM-DD-[topic].md` に書き出す（YYYY-MM-DD は実行日、[topic] は調査トピックの短い英語記述）。ソース素材として inbox/ に入れることで、/pipeline の処理対象となる。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **判定** — `[TRUE]` / `[FALSE]` / `[PARTIALLY TRUE]` / `[UNVERIFIED]` + 信頼度 (`High` / `Medium` / `Low`). 判定理由を2–3段落で記述する。
2. **検証対象** — the exact claim being verified, restated clearly. 主張の出所・文脈も記述する。
3. **検証プロセス** — 検証の各ステップを具体的に記述する（どのクエリで何が見つかったか）。本文中で `[1]`, `[2]` のインライン引用を使用する。
4. **根拠テーブル**

   | # | ソース | Tier | 支持/反証 | 要点 | URL |
   |---|--------|------|-----------|------|-----|

5. **反証・矛盾点** — 矛盾するエビデンスや未解決の対立を2–3段落で分析する。
6. **注意事項** — caveats, context that affects interpretation, single-origin warnings
7. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## Guardrails

- **1ソースだけでTRUE禁止** — minimum 2 independent sources for TRUE verdict.
- **Single-origin chain 検出** — if all confirming sources trace back to one original, flag it: `[単一起源注意]`.
- **未発見 ≠ FALSE** — absence of evidence is not evidence of absence. Use UNVERIFIED.
- **政治的・感情的主張** — stick to verifiable factual components only. Flag subjective elements.
- **日付の重要性** — note when claims may have been true at one time but are now outdated.
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Complex multi-faceted claims → `/deep-research`
- Historical context needed → `/trend-scan`
- Latest news angle → `/news-digest`

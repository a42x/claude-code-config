---
name: web-research
description: "Focused web research with Tavily MCP. Trigger: recent facts, vendor docs, API changes, pricing, migration guides, 'check docs', 'latest', 'compare X vs Y', single-topic lookup."
argument-hint: [topic-or-question]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "3.0.0"
---

# Web research

Investigate **$ARGUMENTS** using Tavily MCP tools.

This skill is for **narrow, decision-useful research**. Do not sprawl. If the request is broad, convert it into a tightly scoped question before using tools.

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

Use tools in this order. Escalate only when insufficient:

1. **search** — always start here. Max 3 queries. `search_depth: "basic"`, `max_results: 3`.
2. **extract** — search snippet では不十分な場合のみ. Max 1 URL. `query` + `chunks_per_source: 3` を使用.

## Token optimization

- search の `content` で結論が出せる場合、extract をスキップ
- 最初の 2 queries で結論が安定したら、追加検索をスキップ
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"、"もっと詳しく"）、バジェット上限内で対応する**

## Method

1. Rewrite the user request as one crisp research question.
2. Generate 2–4 search queries, starting with the most constrained.
3. Prefer primary sources (official docs > vendor pages > standards > announcements).
4. Search first. Extract only the few URLs that matter.
5. Stop once the conclusion is stable.
6. Separate: verified facts (with URL) / interpretation / unknowns.

## 出力ファイル

最終レポートは Write ツールで `tmp/web-research-YYYY-MM-DD.md` に書き出す（YYYY-MM-DD は実行日）。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **結論** `[High]`/`[Medium]`/`[Low]` — prefix time-sensitive info with **as of YYYY-MM-DD**. 結論に至った理由・背景を2–3段落で記述する。
2. **エビデンス** — 各ソースごとにサブセクションを設け、そのソースから得られた具体的な情報（数値、日付、引用）を記述する。本文中で `[1]`, `[2]` のインライン引用を使用する。
3. **未確認事項** — 調査で判明しなかった点、追加調査が必要な点を具体的に列挙する。
4. **推奨次ステップ** — if insufficient, recommend `/deep-research`
5. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## Guardrails

- Reject marketing fluff; prefer implementation or policy pages.
- If sources disagree, say so directly and name the conflict.
- If 3 search queries yield no useful results, stop and recommend `/deep-research`.
- **NEVER use WebSearch or WebFetch.**

## Good fit

- latest pricing, packaging changes
- official migration guides
- compare two API capabilities using vendor docs
- check whether a policy / feature / limitation exists now
- single factual question with a clear answer

## Bad fit — escalate to `/deep-research`

- multi-source comparison requiring 5+ pages
- competitive landscape analysis
- architecture decisions needing broad coverage
- "research everything about X"

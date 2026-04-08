---
name: deep-research
description: "Multi-source deep research via Tavily MCP. Trigger: competitor analysis, landscape scan, architecture decision, high-stakes comparison, broad technical survey, multi-page docs."
argument-hint: [decision-or-topic]
context: fork
model: opus
allowed-tools: mcp__tavily__*, Write
version: "3.0.0"
---

# Deep research

Research **$ARGUMENTS** thoroughly using Tavily MCP tools.

This skill is for **multi-source, higher-cost research** where single-page search is not enough. Work methodically and stop when additional searching is unlikely to change the recommendation.

## CRITICAL: Tool requirements

You MUST use Tavily MCP tools for ALL web research. Find and use the tools whose names contain "tavily":

- **Research** → tool name matches `*tavily*research*` — comprehensive multi-source research (**PRIMARY**)
- **Search** → tool name matches `*tavily*search*` — web queries (supplement/fallback)
- **Extract** → tool name matches `*tavily*extract*` — pull content from specific URLs (fallback)

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

## Research protocol

1. Restate the task as a decision question.
2. Break it into 3–5 subquestions.
3. **Primary path — `tavily_research`**:
   - すべてのサブクエスチョンを含む構造化プロンプトで `tavily_research` を呼び出す
   - Model: `"mini"` for focused questions, `"pro"` for broad landscape analysis
   - research API が包括的な結果を返した場合 → そのまま deliverable へ進む
4. **Supplement path — search + extract** (research が不十分な場合のみ):
   - research 結果にギャップがある場合、targeted search で補完する
   - `search_depth: "basic"`, `max_results: 3` で開始
   - search の `content` で十分なら extract をスキップ
   - extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
5. Prefer first-party sources, then credible third-party analysis.
6. **Cross-validate**: key claims need 2+ independent sources.
7. **Stop rule** — halt when ANY is true:
   - recommendation is stable across sources
   - 3 consecutive searches yield no new information
   - tool budget exhausted

## Tool budget

| Tool | Max calls | When to use |
|------|-----------|-------------|
| **research** | 1 | **Primary** — comprehensive multi-source research を最初に試す |
| **search** | 6 | **Supplement** — research 結果にギャップがある場合のみ |
| **extract** | 4 | **Supplement** — search snippet では情報不足の場合のみ |

> **コスト比較**: research × 1 で search × 10 + extract × 8 相当の網羅性が得られる

## Token optimization

- research API を最優先で使用し、search + extract は補完用途に限定する
- search 使用時は `search_depth: "basic"`, `max_results: 3` をデフォルトで使用
- search の `content` で十分なら extract をスキップ
- extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"）、そちらを優先する**

## Source quality tiers

Categorize every source:

- **Tier 1 (Primary)**: official docs, vendor pages, standards, RFCs, direct announcements
- **Tier 2 (Credible third-party)**: reputable publications, peer-reviewed analysis, established blogs
- **Tier 3 (Community)**: forums, Stack Overflow, personal blogs, social media

Key claims must be supported by at least 2 independent sources, with at least 1 from Tier 1 or Tier 2.

## Analysis discipline

For each important claim, distinguish:

- **Fact**: directly supported by a source (cite URL)
- **Interpretation**: your synthesis from multiple facts
- **Risk**: what could still make this wrong

## 出力ファイル

最終レポートは Write ツールで `inbox/deep-research-YYYY-MM-DD-[topic].md` に書き出す（YYYY-MM-DD は実行日、[topic] は調査トピックの短い英語記述）。ソース素材として inbox/ に入れることで、/pipeline の処理対象となる。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Mandatory deliverable

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **判断サマリー** `[High]` `[Medium]` `[Low]` — prefix time-sensitive info with **as of YYYY-MM-DD**. 判断の根拠を3–5段落で詳述する。
2. **サマリーに対する最も強い反論** — 反論の内容と、それに対する評価を2–3段落で記述する。
3. **ソース別エビデンス** — source tier ごとにグループ化し、各ソースから得た具体的な情報（数値・引用・事実）を記述する。本文中で `[1]`, `[2]` のインライン引用を使用する。

   | # | ソース | Tier | 要点 | URL |
   |---|--------|------|------|-----|

4. **未解明事項** — 調査で判明しなかった点を具体的に列挙する。
5. **推奨アクション** — 具体的な次のステップを優先度順に記述する。
6. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## When comparing options

| Dimension | Description |
|-----------|-------------|
| scope fit | How well does it match the requirements? |
| implementation friction | How hard is adoption? |
| lock-in / reversibility | How easy to switch away? |
| operational risk | What can go wrong in production? |
| evidence quality | How strong is the supporting data? |

## Anti-failure rules

- Do not hide source conflicts — surface them explicitly.
- Do not average weak sources into fake certainty.
- Do not provide a recommendation without naming the main downside.
- Do not continue researching after hitting diminishing returns.
- **NEVER use WebSearch or WebFetch.**

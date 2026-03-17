---
name: market-check
description: "財務・市場情報の確認。Trigger: 株価, 決算, 業績, 時価総額, 市場動向, 財務情報, 'stock', 'earnings', 'market cap', 'financial'."
argument-hint: [company-or-ticker]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# マーケットチェック

**$ARGUMENTS** に関する財務・市場情報を金融ドメインから収集・整理する。

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
| **search** | 4 | Financial data queries with domain filters |
| **extract** | 1 | search snippet では決算数値が不十分な場合のみ |

## Token optimization

- `search_depth: "basic"`, `max_results: 3` をデフォルトで使用
- 金融データは search snippet に数値が含まれることが多い — extract 前に snippet を確認
- Analyst coverage search は主要数値（株価・時価総額・EPS）が取得済みの場合はスキップ可能
- extract 時は `query` + `chunks_per_source: 3` で財務データのチャンクのみ取得
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"）、そちらを優先する**

## Method

1. **Identify the entity** — resolve company name, ticker symbol, and primary market from $ARGUMENTS.
2. **Financial data search** — query with:
   - `include_domains: ["finance.yahoo.com", "bloomberg.com", "reuters.com", "nikkei.com", "kabutan.jp", "minkabu.jp"]`
   - `time_range: "month"`
   - Append keywords: "stock price", "earnings", "決算", "業績" as appropriate
3. **Earnings/results search** — separate query for latest quarterly results.
4. **Analyst coverage search** — search for analyst ratings, price targets, consensus estimates.
5. **Extract** only when search snippets lack specific figures (revenue, EPS, guidance).

## 出力ファイル

最終レポートは Write ツールで `tmp/market-check-YYYY-MM-DD.md` に書き出す（YYYY-MM-DD は実行日）。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **⚠️ 免責事項** — **MANDATORY, ALWAYS FIRST**:
   > この情報は調査目的で提供されており、投資助言ではありません。投資判断はご自身の責任で、専門家にご相談ください。
2. **財務サマリー**

   | 指標 | 値 | 時点 | ソース |
   |------|-----|------|--------|

   Include: stock price, market cap, P/E, revenue, net income, EPS (as available)
3. **業績ハイライト** — 最新四半期/年次決算の要約。売上高・営業利益・純利益・EPSの前年比変化を含め、2–3段落で記述する。本文中で `[1]`, `[2]` のインライン引用を使用する。
4. **市場コンテキスト** — セクター動向、同業他社との比較、マクロ要因を2–3段落で記述する。
5. **アナリスト見解** — コンセンサスレーティング、目標株価、主要意見を出典付きで記述する。
6. **データの注意点** — data freshness, currency, any discrepancies between sources
7. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## Guardrails

- **免責事項は必須** — the disclaimer in section 1 must ALWAYS appear. No exceptions.
- **数値は3点セット** — every financial figure must include: date, currency, source. Missing any → flag it.
- **データ鮮度チェック** — data older than 7 days must be flagged: `[データ時点: YYYY-MM-DD — 1週間以上前]`.
- **通貨の明記** — always specify currency (JPY, USD, EUR, etc.).
- **予測と実績の区別** — clearly label forecasts vs. reported actuals.
- **推奨禁止** — NEVER issue buy/sell/hold recommendations.
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Competitive landscape analysis → `/deep-research`
- Time-series trend analysis → `/trend-scan`
- Latest breaking financial news → `/news-digest`

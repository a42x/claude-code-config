---
name: trend-scan
description: "トレンド・時系列変化の分析。Trigger: トレンド, 推移, 変化, 動向分析, 時系列, 増加傾向, 'trend', 'how has X changed', 'trajectory'."
argument-hint: [topic-or-metric]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# トレンドスキャン

**$ARGUMENTS** の時間的変化・トレンドを時間セグメント比較で分析する。

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
| **search** | 5 | Time-segmented queries across different periods |
| **extract** | 2 | search snippet では数値・データ不足の場合のみ |

## Token optimization

- `search_depth: "basic"`, `max_results: 3` をデフォルトで使用
- search の `content` フィールドで十分な数値が得られた場合、extract をスキップ
- extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
- 3 つの time_range 検索の前に、最初の結果で十分な時系列データがあるか確認し、不要な期間はスキップ
- **ユーザーが明示的にパラメータを指定した場合（例: "advanced で検索して"）、そちらを優先する**

## Method

1. **Define the metric/topic** — clarify what aspect of $ARGUMENTS to track over time.
2. **Time-segmented search** — execute searches across 3 time windows:
   - **Recent**: `time_range: "week"` — current state
   - **Medium-term**: `time_range: "month"` — recent developments
   - **Long-term**: `time_range: "year"` — broader trajectory
3. **Supplementary search** — if user specifies date range, use targeted queries with date terms instead of `time_range`.
4. **Compare segments** — identify:
   - Direction of change between periods
   - Inflection points (when did the trend shift?)
   - Acceleration or deceleration
5. **Extract** data-rich sources (reports, statistics, analysis) for precise figures.
6. **Synthesize** — build a coherent narrative of the trend.

## Trend direction indicators

Use these labels consistently:

| Indicator | Meaning |
|-----------|---------|
| `[上昇 ↑]` | Clear upward trend |
| `[下降 ↓]` | Clear downward trend |
| `[横ばい →]` | Stable, no significant change |
| `[変曲点 ⤴]` | Trend reversal or significant shift |
| `[データ不足]` | Insufficient data for this period |

## 出力ファイル

最終レポートは Write ツールで `inbox/trend-scan-YYYY-MM-DD-[topic].md` に書き出す（YYYY-MM-DD は実行日、[topic] は調査トピックの短い英語記述）。ソース素材として inbox/ に入れることで、/pipeline の処理対象となる。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **トレンドサマリー** — direction indicator + 全体的な軌跡の要約を2–3段落で記述する。本文中で `[1]`, `[2]` のインライン引用を使用する。
2. **タイムライン**
   - Format: `[期間] 方向indicator — 概要 [N]`
   - From oldest to newest
   - 各エントリは具体的な数値・データポイントを含め、2–3文で記述する。
3. **変化要因** — 観察された変化の主要ドライバーを、ソース帰属付きで2–3段落で分析する。
4. **今後の予測** — expert/analyst forecasts only (with attribution). Never generate your own predictions. 各予測の前提条件も記述する。
5. **データの限界** — gaps in data, periods with no coverage, methodology differences between sources
6. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (YYYY-MM-DD)`

## Guardrails

- **相関 ≠ 因果** — never imply causation without explicit evidence. Use "correlates with" not "caused by".
- **予測は出典必須** — all forward-looking statements must cite a specific analyst, institution, or report.
- **データ空白期間の補間禁止** — if no data exists for a period, mark it as `[データ不足]`. Do not interpolate.
- **サンプルサイズ注意** — if trend is based on limited data points, flag it explicitly.
- **バイアス警告** — note if sources have known biases (e.g., industry-funded reports).
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Deep competitive/landscape analysis → `/deep-research`
- Latest news only → `/news-digest`
- Financial metrics specifically → `/market-check`

---
name: news-digest
description: "ニュース要約・タイムライン作成。Trigger: 最新ニュース, ニュースまとめ, 報道状況, 最近の動向, ニュースダイジェスト, 'news about', 'latest news'."
argument-hint: [topic]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# ニュースダイジェスト

**$ARGUMENTS** に関する最新ニュースを収集し、タイムライン形式でまとめる。

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
| **search** | 3 | News queries with time_range and domain filters |
| **extract** | 1 | search snippet では記事要約に不十分な場合のみ |

## Token optimization

- ニュース記事は search snippet が充実しているため、多くの場合 extract 不要
- `max_results: 5` でニュース検索し、snippet でタイムライン構成する
- Supplementary search は initial results が 2 件以下の場合のみ実行
- extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
- **ユーザーが明示的にパラメータを指定した場合（例: "詳しく調べて"、"もっと多く"）、バジェット上限内で対応する**

## Method

1. **Initial broad search** — query `$ARGUMENTS` with:
   - `time_range: "day"` (or `"week"` if daily results are sparse)
   - `include_domains: ["reuters.com", "bloomberg.com", "nikkei.com", "nhk.or.jp", "apnews.com", "bbc.com"]`
   - Append "ニュース" or "news" to query based on user language
2. **Supplementary search** — if initial results are thin, broaden:
   - Remove domain filter, keep `time_range`
   - Try alternate query phrasings
3. **Extract key articles** — only for articles that need full-text for accurate summarization.
4. **Deduplicate** — merge wire service rewrites into single timeline entries.
5. **Order chronologically** — newest first.

## 出力ファイル

最終レポートは Write ツールで `tmp/news-digest-YYYY-MM-DD.md` に書き出す（YYYY-MM-DD は実行日）。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **トピック概要** — トピックの現状を2–3段落で要約する。背景・経緯・現在の状況を含める。本文中で `[1]`, `[2]` のインライン引用を使用する。
2. **ニュースタイムライン**
   - Format: `[YYYY-MM-DD] **見出し** — 要約 [N]`
   - Chronological order, newest first
   - 各エントリは2–3文で、具体的な事実・数値・関係者のコメントを含める。
3. **注目ポイント** — 4–6 bullet points highlighting key developments, implications, or emerging patterns. 各ポイントに根拠となるソースの `[N]` を付記する。
4. **今後の展望** — 今後予想される展開や注目すべきイベント・日程を記述する。
5. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] ソース名: タイトル — URL (YYYY-MM-DD)`

## Guardrails

- **社説・意見記事を除外** — report factual coverage only. If opinion is included, label it explicitly as `[意見]`.
- **日付は原文ソースから** — do not infer or estimate publication dates.
- **噂と報道を区別** — unconfirmed reports must be prefixed with `[未確認]`.
- **速報の注意** — for breaking news, note that details may change: `[速報 — 情報は変動の可能性あり]`.
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Broad analysis beyond news → `/deep-research`
- Fact verification needed → `/fact-check`
- Historical trend context → `/trend-scan`

---
name: docs-dive
description: "公式ドキュメント深掘り調査。Trigger: ドキュメント調査, API仕様, 使い方, 公式ドキュメント, 設定方法, 'check docs', 'API reference', 'how to configure'."
argument-hint: [library-or-tool]
context: fork
allowed-tools: mcp__tavily__*, Write
version: "1.0.0"
---

# ドキュメント深掘り

**$ARGUMENTS** の公式ドキュメントを体系的に調査し、構造化された技術リファレンスを作成する。

## CRITICAL: Tool requirements

You MUST use Tavily MCP tools for ALL web research. Find and use the tools whose names contain "tavily":

- **Search** → tool name matches `*tavily*search*` — web queries
- **Extract** → tool name matches `*tavily*extract*` — pull content from specific URLs
- **Map** → tool name matches `*tavily*map*` — discover site structure
- **Crawl** → tool name matches `*tavily*crawl*` — fetch page content with instructions

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
| **search** | 2 | Find official docs URL, specific topics |
| **map** | 1 | Discover documentation site structure（構造不明時のみ） |
| **crawl** | 1 | Fetch documentation sections with targeted instructions |
| **extract** | 2 | Pull specific pages (API ref, config, examples) |

## Token optimization

- search で公式ドキュメント URL が判明したら、map で構造確認してから crawl/extract する（無駄な呼び出しを防ぐ）
- map の `max_breadth` を 10 に抑える（過剰な URL 発見を防ぐ）
- crawl/extract は最も重要なセクション（API ref, config）のみに絞る
- extract 時は `query` + `chunks_per_source: 3` で関連チャンクのみ取得
- **ユーザーが明示的にパラメータを指定した場合（例: "もっと広く調べて"）、バジェット上限内で対応する**

## Method

1. **Discover official docs** — search for `$ARGUMENTS` official documentation URL.
2. **Map site structure** — use `map` on the docs root URL:
   - `max_depth: 2`
   - `max_breadth: 15`
   - Identify: getting started, API reference, configuration, examples, changelog sections
3. **Crawl key sections** — use `crawl` on the most relevant sections:
   - `format: "markdown"`
   - Set `instructions` to focus on: API signatures, parameters, return types, configuration options
4. **Extract specific pages** — for pages needing detailed information (API reference tables, config schemas).
5. **Synthesize** — organize findings into a structured reference.

## 出力ファイル

最終レポートは Write ツールで `inbox/docs-dive-YYYY-MM-DD-[topic].md` に書き出す（YYYY-MM-DD は実行日、[topic] は調査トピックの短い英語記述）。ソース素材として inbox/ に入れることで、/pipeline の処理対象となる。レスポンス末尾にファイルパスを明記し、ユーザーが直接閲覧できるようにする。

## Output contract

Write ツールで書き出すレポートは、以下のセクション構成に従う:

1. **概要** — ツール/ライブラリの説明、現バージョン、最終更新日を2–3段落で記述する。ユースケースや位置づけも含める。本文中で `[1]`, `[2]` のインライン引用を使用する。
2. **APIリファレンス** (if applicable) — 主要なメソッド/エンドポイントを網羅的に記述する。

   | メソッド/エンドポイント | パラメータ | 戻り値 | 説明 |
   |------------------------|-----------|--------|------|

   各メソッドについて、パラメータの型・デフォルト値・必須/任意を明記する。
3. **設定・構成** — 設定オプション、環境変数、デフォルト値を網羅的に記述する。設定例を含める。
4. **使用例** — code examples from the official docs (verbatim, with source URL `[N]`). 各例に解説を付記する。
5. **注意点・制限事項** — 既知の制限、Breaking Changes、非推奨機能を具体的に記述する。
6. **関連リソース** — links to: changelog, migration guides, community resources, GitHub repo
7. **ソース一覧** — 本文中の `[N]` と対応させる。Format: `[N] タイトル — URL (ドキュメントバージョン, YYYY-MM-DD)`

## Guardrails

- **公式ドキュメント優先** — always prefer official docs over blog posts or tutorials. If using non-official sources, label them: `[非公式]`.
- **バージョン・更新日記載** — note documentation version and last update date when available.
- **コード例は原文から** — code snippets must come from the source documentation. NEVER fabricate code examples.
- **認証壁の明記** — if documentation requires authentication or is behind a paywall, note it: `[要認証]`.
- **非推奨は明示** — deprecated features must be labeled: `[DEPRECATED]` with migration path if available.
- **バージョン差異** — if behavior differs across versions, note which version the information applies to.
- **NEVER use WebSearch or WebFetch.**

## Escalation

- Broad comparison of alternatives → `/deep-research`
- Security vulnerabilities in the library → `/security-check`
- Quick single-fact lookup → `/web-research`

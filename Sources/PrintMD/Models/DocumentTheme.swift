enum DocumentTheme: String, CaseIterable, Identifiable {
    case clean
    case compact
    case classic
    case warm
    case technical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清爽"
        case .compact: return "紧凑"
        case .classic: return "经典"
        case .warm: return "暖色"
        case .technical: return "技术"
        }
    }

    var css: String {
        switch self {
        case .clean:
            return """
            :root {
              --preview-background: #d9dde3;
              --sheet-background: #ffffff;
              --body-text: #17202a;
              --muted-text: #5c6673;
              --rule-color: #d7dde5;
              --strong-rule-color: #aeb9c7;
              --inline-code-background: #f3f5f8;
              --table-header-background: #eef3f8;
              --table-row-alt-background: #fafbfc;
              --link-color: #1b5f97;
              --heading-color: #123c5d;
              --blockquote-background: #f7f9fb;
              --sheet-padding-horizontal: 16mm;
              --sheet-padding-vertical: 15mm;
              --body-font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", "Helvetica Neue", Arial, sans-serif;
              --body-line-height: 1.58;
              --block-spacing: 0.62em;
            }
            """

        case .compact:
            return """
            :root {
              --preview-background: #d5d9df;
              --sheet-background: #ffffff;
              --body-text: #151a20;
              --muted-text: #555f6b;
              --rule-color: #d1d7df;
              --strong-rule-color: #9ea9b7;
              --inline-code-background: #f1f3f6;
              --table-header-background: #e9eef4;
              --table-row-alt-background: #fafafa;
              --link-color: #155d8c;
              --heading-color: #173b55;
              --blockquote-background: #f6f7f9;
              --sheet-padding-horizontal: 13mm;
              --sheet-padding-vertical: 12mm;
              --body-font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", Arial, sans-serif;
              --body-line-height: 1.48;
              --block-spacing: 0.48em;
            }

            h1 { font-size: 1.68em; }
            h2 { font-size: 1.28em; }
            h3 { font-size: 1.08em; }
            th, td { padding: 0.28em 0.42em; }
            pre { padding: 0.58em 0.68em; }
            """

        case .classic:
            return """
            :root {
              --preview-background: #d7d9dd;
              --sheet-background: #ffffff;
              --body-text: #1f2328;
              --muted-text: #626a73;
              --rule-color: #d6d2c8;
              --strong-rule-color: #a79c88;
              --inline-code-background: #f5f3ef;
              --table-header-background: #f0ede6;
              --table-row-alt-background: #fbfaf7;
              --link-color: #5d4c2f;
              --heading-color: #2d2a24;
              --blockquote-background: #f8f6f1;
              --sheet-padding-horizontal: 18mm;
              --sheet-padding-vertical: 17mm;
              --body-font: Charter, Georgia, "Times New Roman", "Songti SC", "Noto Serif CJK SC", serif;
              --body-line-height: 1.66;
              --block-spacing: 0.68em;
            }

            h1, h2 { border-color: var(--strong-rule-color); }
            """

        case .warm:
            return """
            :root {
              --preview-background: #d9d3ca;
              --sheet-background: #fffdf8;
              --body-text: #25211b;
              --muted-text: #6d6458;
              --rule-color: #ddd1bf;
              --strong-rule-color: #b9a27f;
              --inline-code-background: #f6efe3;
              --table-header-background: #f4ead9;
              --table-row-alt-background: #fff9ef;
              --link-color: #7b4d18;
              --heading-color: #533816;
              --blockquote-background: #f8f0e3;
              --sheet-padding-horizontal: 17mm;
              --sheet-padding-vertical: 16mm;
              --body-font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", Arial, sans-serif;
              --body-line-height: 1.62;
              --block-spacing: 0.64em;
            }
            """

        case .technical:
            return """
            :root {
              --preview-background: #d4d9df;
              --sheet-background: #ffffff;
              --body-text: #101820;
              --muted-text: #56616f;
              --rule-color: #cfd8e3;
              --strong-rule-color: #8ea0b5;
              --inline-code-background: #eef4fa;
              --table-header-background: #e6eef7;
              --table-row-alt-background: #f7fafd;
              --link-color: #0068a8;
              --heading-color: #0b3d62;
              --blockquote-background: #f3f7fb;
              --sheet-padding-horizontal: 15mm;
              --sheet-padding-vertical: 14mm;
              --body-font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Noto Sans CJK SC", Arial, sans-serif;
              --body-line-height: 1.54;
              --block-spacing: 0.56em;
            }

            pre, code {
              font-family: "SF Mono", Menlo, Monaco, Consolas, monospace;
            }

            table {
              font-size: 0.95em;
            }
            """
        }
    }
}

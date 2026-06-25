import Darwin
import Foundation
import cmark_gfm
import cmark_gfm_extensions

final class GitHubMarkdownRenderer {
    private let extensionNames = [
        "table",
        "strikethrough",
        "autolink",
        "tagfilter",
        "tasklist"
    ]

    func render(_ source: String) -> String {
        cmark_gfm_core_extensions_ensure_registered()

        let options = CMARK_OPT_DEFAULT
            | CMARK_OPT_FOOTNOTES
            | CMARK_OPT_GITHUB_PRE_LANG
            | CMARK_OPT_SMART
            | CMARK_OPT_VALIDATE_UTF8

        guard let parser = cmark_parser_new(options) else {
            return fallbackHTML(for: source)
        }

        defer {
            cmark_parser_free(parser)
        }

        for extensionName in extensionNames {
            guard let syntaxExtension = cmark_find_syntax_extension(extensionName) else {
                continue
            }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }

        source.withCString { pointer in
            cmark_parser_feed(parser, pointer, strlen(pointer))
        }

        guard let document = cmark_parser_finish(parser) else {
            return fallbackHTML(for: source)
        }

        defer {
            cmark_node_free(document)
        }

        let extensions = cmark_parser_get_syntax_extensions(parser)
        guard let htmlPointer = cmark_render_html(document, options, extensions) else {
            return fallbackHTML(for: source)
        }

        defer {
            free(htmlPointer)
        }

        return String(cString: htmlPointer)
    }

    private func fallbackHTML(for source: String) -> String {
        "<pre><code>\(source.escapedHTML)</code></pre>"
    }
}

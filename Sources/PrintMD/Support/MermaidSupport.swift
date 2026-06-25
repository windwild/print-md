import Foundation

enum MermaidSupport {
    static let inlineScript: String = {
        guard
            let url = Bundle.module.url(forResource: "mermaid.min", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            return "window.__printMDMermaidLoadError = true;"
        }

        return source.replacingOccurrences(
            of: "</script",
            with: "<\\/script",
            options: [.caseInsensitive]
        )
    }()
}

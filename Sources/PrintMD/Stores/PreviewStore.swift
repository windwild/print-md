import AppKit
import Foundation

@MainActor
final class PreviewStore: ObservableObject {
    @Published private(set) var markdownURL: URL?
    @Published private(set) var stylesheetURL: URL?
    @Published private(set) var markdownSource = ""
    @Published private(set) var stylesheetSource = ""
    @Published private(set) var renderedHTML = HTMLDocumentBuilder.emptyDocument()
    @Published private(set) var statusMessage = "就绪"
    @Published var errorMessage: String?
    @Published var pageSize: PageSize = .a4 {
        didSet {
            statusMessage = pageSize.statusTitle
            renderPreview()
        }
    }
    @Published var selectedTheme: DocumentTheme = .clean {
        didSet {
            statusMessage = "主题：\(selectedTheme.title)"
            renderPreview()
        }
    }
    @Published var printMode: PrintMode = .standard {
        didSet {
            if printMode == .eco {
                duplexMode = .shortEdge
            }
            statusMessage = printMode.statusTitle
            renderPreview()
        }
    }
    @Published var duplexMode: PrintDuplexMode = .longEdge {
        didSet { statusMessage = duplexMode.statusTitle }
    }
    @Published var fontSize: Double = 10 {
        didSet {
            statusMessage = "字号：\(Int(fontSize)) pt"
            renderPreview()
        }
    }
    @Published private(set) var printRequestID = 0

    private let renderer = GitHubMarkdownRenderer()
    private let minimumFontSize = 8.0
    private let maximumFontSize = 36.0

    var baseURL: URL? {
        markdownURL?.deletingLastPathComponent()
    }

    var documentTitle: String {
        markdownURL?.lastPathComponent ?? "未打开 Markdown"
    }

    var stylesheetTitle: String {
        if let stylesheetURL {
            return "\(selectedTheme.title) + \(stylesheetURL.lastPathComponent)"
        }

        return selectedTheme.title
    }

    var canPrint: Bool {
        markdownURL != nil
    }

    var canReload: Bool {
        markdownURL != nil || stylesheetURL != nil
    }

    var canDecreaseFontSize: Bool {
        fontSize > minimumFontSize
    }

    var canIncreaseFontSize: Bool {
        fontSize < maximumFontSize
    }

    var canChangeDuplexMode: Bool {
        printMode == .standard
    }

    func openMarkdown() {
        guard let url = FileSelectionService.chooseMarkdownFile() else { return }
        openMarkdown(from: url)
    }

    func openMarkdown(from url: URL) {
        let fileURL = url.standardizedFileURL
        guard MarkdownFileType.isSupported(fileURL) else {
            errorMessage = "\(fileURL.lastPathComponent) 不是支持的 Markdown 文件。"
            statusMessage = "只支持 Markdown 文件"
            return
        }

        loadMarkdown(from: fileURL)
    }

    func openStyleSheet() {
        guard let url = FileSelectionService.chooseCSSFile() else { return }
        loadStyleSheet(from: url)
    }

    func reloadFiles() {
        if let markdownURL {
            loadMarkdown(from: markdownURL, preserveStatusPrefix: "Reloaded")
        }

        if let stylesheetURL {
            loadStyleSheet(from: stylesheetURL, preserveStatusPrefix: "Reloaded")
        }
    }

    func clearStyleSheet() {
        stylesheetURL = nil
        stylesheetSource = ""
        statusMessage = "已清除自定义 CSS，使用\(selectedTheme.title)主题"
        renderPreview()
    }

    func increaseFontSize() {
        fontSize = min(maximumFontSize, fontSize + 1)
    }

    func decreaseFontSize() {
        fontSize = max(minimumFontSize, fontSize - 1)
    }

    func resetFontSize() {
        fontSize = 10
    }

    func requestPrint() {
        guard canPrint else { return }
        printRequestID += 1
    }

    private func loadMarkdown(from url: URL, preserveStatusPrefix prefix: String = "Opened") {
        do {
            markdownSource = try TextFileReader.read(url)
            markdownURL = url
            errorMessage = nil
            statusMessage = "\(localizedStatusPrefix(prefix)) \(url.lastPathComponent)"
            renderPreview()
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "无法打开 \(url.lastPathComponent)"
        }
    }

    private func loadStyleSheet(from url: URL, preserveStatusPrefix prefix: String = "Loaded") {
        do {
            stylesheetSource = try TextFileReader.read(url)
            stylesheetURL = url
            errorMessage = nil
            statusMessage = "\(localizedStatusPrefix(prefix)) \(url.lastPathComponent)"
            renderPreview()
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "无法导入 \(url.lastPathComponent)"
        }
    }

    private func localizedStatusPrefix(_ prefix: String) -> String {
        switch prefix {
        case "Opened": return "已打开"
        case "Loaded": return "已导入"
        case "Reloaded": return "已重新载入"
        default: return prefix
        }
    }

    private func renderPreview() {
        let previewSource = MarkdownPreprocessor.stripFrontMatter(from: markdownSource)
        let body = previewSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? HTMLDocumentBuilder.emptyBody()
            : renderer.render(previewSource)

        renderedHTML = HTMLDocumentBuilder.document(
            title: markdownURL?.lastPathComponent ?? "PrintMD Preview",
            body: body,
            themeCSS: selectedTheme.css,
            userCSS: stylesheetSource,
            fontSize: fontSize,
            pageSize: pageSize,
            printMode: printMode
        )
    }
}

enum MarkdownFileType {
    static let supportedExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn"]

    static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}

enum MarkdownPreprocessor {
    static func stripFrontMatter(from source: String) -> String {
        guard source.hasPrefix("---") else { return source }

        let normalizedSource = source.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalizedSource.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first == "---" else { return source }

        for index in lines.indices.dropFirst() where lines[index] == "---" {
            let contentStart = lines.index(after: index)
            return lines[contentStart...].joined(separator: "\n")
        }

        return source
    }
}

enum TextFileReader {
    static func read(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian, .isoLatin1]

        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return text
            }
        }

        throw TextFileError.unsupportedEncoding(url.lastPathComponent)
    }
}

enum TextFileError: LocalizedError {
    case unsupportedEncoding(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedEncoding(let name):
            return "\(name) 的文本编码暂不支持。"
        }
    }
}

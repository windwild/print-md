import AppKit
import UniformTypeIdentifiers

enum FileSelectionService {
    static func chooseMarkdownFile() -> URL? {
        chooseFile(
            title: "打开 Markdown 文件",
            prompt: "打开",
            contentTypes: MarkdownFileType.supportedExtensions
                .compactMap { UTType(filenameExtension: $0) } + [.plainText]
        )
    }

    static func chooseCSSFile() -> URL? {
        chooseFile(
            title: "导入 CSS 主题",
            prompt: "导入",
            contentTypes: [
                UTType(filenameExtension: "css"),
                .plainText
            ].compactMap { $0 }
        )
    }

    private static func chooseFile(title: String, prompt: String, contentTypes: [UTType]) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.prompt = prompt
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = contentTypes

        return panel.runModal() == .OK ? panel.url : nil
    }
}

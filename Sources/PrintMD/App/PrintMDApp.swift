import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        enqueueOpenFiles([URL(fileURLWithPath: filename)])
        return true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        enqueueOpenFiles(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
    }

    private func enqueueOpenFiles(_ urls: [URL]) {
        Task { @MainActor in
            ExternalFileOpenCoordinator.shared.open(urls)
        }
    }
}

@main
struct PrintMDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PreviewStore()

    var body: some Scene {
        WindowGroup("PrintMD") {
            ContentView(store: store)
                .frame(minWidth: 980, minHeight: 720)
                .onAppear { [store] in
                    ExternalFileOpenCoordinator.shared.installHandler { [weak store] url in
                        store?.openMarkdown(from: url)
                    }
                }
        }
        .defaultSize(width: 1120, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("打开 Markdown...") {
                    store.openMarkdown()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("导入 CSS 主题...") {
                    store.openStyleSheet()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button("重新载入文件") {
                    store.reloadFiles()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!store.canReload)

                Button("清除自定义 CSS") {
                    store.clearStyleSheet()
                }
                .disabled(store.stylesheetURL == nil)
            }

            CommandGroup(replacing: .printItem) {
                Button("打印...") {
                    store.requestPrint()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(!store.canPrint)
            }

            CommandMenu("预览") {
                Picker("主题", selection: $store.selectedTheme) {
                    ForEach(DocumentTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }

                Picker("打印模式", selection: $store.printMode) {
                    ForEach(PrintMode.allCases) { printMode in
                        Text(printMode.title).tag(printMode)
                    }
                }

                Picker("双面打印", selection: $store.duplexMode) {
                    ForEach(PrintDuplexMode.allCases) { duplexMode in
                        Text(duplexMode.title).tag(duplexMode)
                    }
                }
                .disabled(!store.canChangeDuplexMode)

                Divider()

                Button("放大字号") {
                    store.increaseFontSize()
                }
                .keyboardShortcut("+", modifiers: .command)
                .disabled(!store.canIncreaseFontSize)

                Button("缩小字号") {
                    store.decreaseFontSize()
                }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(!store.canDecreaseFontSize)

                Button("重置字号") {
                    store.resetFontSize()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}

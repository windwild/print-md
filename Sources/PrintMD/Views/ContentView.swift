import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PreviewStore

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ZStack(alignment: .top) {
                PreviewWebView(
                    html: store.renderedHTML,
                    baseURL: store.baseURL,
                    pageSize: store.pageSize,
                    printMode: store.printMode,
                    duplexMode: store.duplexMode,
                    printRequestID: store.printRequestID
                )

                if let errorMessage = store.errorMessage {
                    errorBanner(errorMessage)
                        .padding(.top, 14)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.openMarkdown()
                } label: {
                    toolbarButtonLabel("打开 MD", systemImage: "doc.text")
                }
                .help("打开 .md 或 .markdown 文件")

                Button {
                    store.openStyleSheet()
                } label: {
                    toolbarButtonLabel("导入 CSS", systemImage: "paintbrush")
                }
                .help("导入自定义 CSS，覆盖当前打印主题")

                HStack(spacing: 6) {
                    Text("主题")
                        .foregroundStyle(.secondary)

                    Picker("主题", selection: $store.selectedTheme) {
                        ForEach(DocumentTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 86)
                }
                .help("选择内置打印主题；导入 CSS 会继续叠加覆盖")

                Divider()

                HStack(spacing: 6) {
                    Text("模式")
                        .foregroundStyle(.secondary)

                    Picker("模式", selection: $store.printMode) {
                        ForEach(PrintMode.allCases) { printMode in
                            Text(printMode.title).tag(printMode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 82)
                }
                .help("环保模式会使用双面短边装订，并把每面纸排成 2 页")

                Button {
                    store.decreaseFontSize()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(!store.canDecreaseFontSize)
                .help("缩小 Markdown 字号，最小 8 pt")

                Text("\(Int(store.fontSize)) pt")
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 46)
                    .help("当前 Markdown 字号")

                Button {
                    store.increaseFontSize()
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!store.canIncreaseFontSize)
                .help("放大 Markdown 字号，最大 36 pt")

                HStack(spacing: 6) {
                    Text("纸张")
                        .foregroundStyle(.secondary)

                    Picker("纸张", selection: $store.pageSize) {
                        ForEach(PageSize.allCases) { pageSize in
                            Text(pageSize.title).tag(pageSize)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 128)
                }
                .help("选择预览和打印使用的纸张尺寸")

                HStack(spacing: 6) {
                    Text("双面")
                        .foregroundStyle(.secondary)

                    Picker("双面", selection: $store.duplexMode) {
                        ForEach(PrintDuplexMode.allCases) { duplexMode in
                            Text(duplexMode.title).tag(duplexMode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 108)
                }
                .disabled(!store.canChangeDuplexMode)
                .help(store.canChangeDuplexMode ? "设置提交给打印机的单面或双面打印方式" : "环保模式固定为双面短边装订")

                Button {
                    store.requestPrint()
                } label: {
                    toolbarButtonLabel("打印", systemImage: "printer")
                }
                .disabled(!store.canPrint)
                .help(store.canPrint ? "打开系统打印面板" : "请先打开 Markdown 文件")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.documentTitle)
                    .font(.headline)
                    .lineLimit(1)

                Text(store.stylesheetTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            Text(store.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if store.stylesheetURL != nil {
                Button {
                    store.clearStyleSheet()
                } label: {
                    toolbarButtonLabel("清除 CSS", systemImage: "xmark.circle")
                }
                .help("清除已导入的自定义 CSS，保留内置主题")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func toolbarButtonLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .lineLimit(2)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.separator, lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

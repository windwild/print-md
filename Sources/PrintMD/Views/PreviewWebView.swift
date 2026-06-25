import AppKit
import ApplicationServices
import SwiftUI
import WebKit

struct PreviewWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let pageSize: PageSize
    let printMode: PrintMode
    let duplexMode: PrintDuplexMode
    let printRequestID: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.pageSize = pageSize
        context.coordinator.printMode = printMode
        context.coordinator.duplexMode = duplexMode

        if context.coordinator.lastHTML != html || context.coordinator.lastBaseURL != baseURL {
            context.coordinator.lastHTML = html
            context.coordinator.lastBaseURL = baseURL
            context.coordinator.isLoading = true
            webView.loadHTMLString(html, baseURL: baseURL)
        }

        guard context.coordinator.lastPrintRequestID != printRequestID else { return }
        context.coordinator.lastPrintRequestID = printRequestID
        context.coordinator.requestPrint(webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML = ""
        var lastBaseURL: URL?
        var lastPrintRequestID = 0
        var isLoading = false
        var pageSize: PageSize = .a4
        var printMode: PrintMode = .standard
        var duplexMode: PrintDuplexMode = .longEdge
        private var pendingPrint = false
        private var isPresentingPrintPanel = false

        func requestPrint(_ webView: WKWebView) {
            pendingPrint = true

            guard !isLoading else { return }
            runPrintOperation(for: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false

            if pendingPrint {
                runPrintOperation(for: webView)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        private func runPrintOperation(for webView: WKWebView) {
            guard !isPresentingPrintPanel else { return }
            pendingPrint = false

            guard let window = webView.window else {
                pendingPrint = true
                DispatchQueue.main.async { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.runPrintOperation(for: webView)
                }
                return
            }

            let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic
            printInfo.paperSize = pageSize.paperSize
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = false
            printInfo.topMargin = 0
            printInfo.bottomMargin = 0
            printInfo.leftMargin = 0
            printInfo.rightMargin = 0
            applyDuplexMode(printMode.effectiveDuplexMode(userSelection: duplexMode), to: printInfo)
            applyPrintMode(to: printInfo)

            waitForPagination(in: webView, attemptsRemaining: 20) { [weak self, weak webView, weak window] in
                guard let self, let webView, let window else { return }
                self.presentPrintOperation(for: webView, in: window, printInfo: printInfo)
            }
        }

        private func applyPrintMode(to printInfo: NSPrintInfo) {
            printInfo.orientation = printMode.printOrientation
            printInfo.dictionary()[NSPrintInfo.AttributeKey.pagesAcross] = NSNumber(value: 1)
            printInfo.dictionary()[NSPrintInfo.AttributeKey.pagesDown] = NSNumber(value: 1)

            printInfo.printSettings[NSPrintInfo.SettingKey("com_apple_print_PrintSettings_PMLayoutNUp")] = NSNumber(value: false)
            printInfo.printSettings[NSPrintInfo.SettingKey("com_apple_print_PrintSettings_PMLayoutColumns")] = NSNumber(value: 1)
            printInfo.printSettings[NSPrintInfo.SettingKey("com_apple_print_PrintSettings_PMLayoutRows")] = NSNumber(value: 1)
            printInfo.printSettings[NSPrintInfo.SettingKey("com_apple_print_PrintSettings_PMLayoutDirection")] = NSNumber(value: 1)

            printInfo.dictionary()[NSPrintInfo.AttributeKey("com.apple.print.PrintSettings.PMLayoutNUp")] = NSNumber(value: false)
            printInfo.dictionary()[NSPrintInfo.AttributeKey("com.apple.print.PrintSettings.PMLayoutColumns")] = NSNumber(value: 1)
            printInfo.dictionary()[NSPrintInfo.AttributeKey("com.apple.print.PrintSettings.PMLayoutRows")] = NSNumber(value: 1)
            printInfo.dictionary()[NSPrintInfo.AttributeKey("com.apple.print.PrintSettings.PMLayoutDirection")] = NSNumber(value: 1)
        }

        private func applyDuplexMode(_ mode: PrintDuplexMode, to printInfo: NSPrintInfo) {
            let pmPrintSettings = OpaquePointer(printInfo.pmPrintSettings())
            _ = PMSetDuplex(pmPrintSettings, PMDuplexMode(mode.printCoreValue))
            printInfo.updateFromPMPrintSettings()

            printInfo.printSettings[NSPrintInfo.SettingKey("sides")] = mode.ippSidesValue
            printInfo.printSettings[NSPrintInfo.SettingKey("Duplex")] = mode.cupsDuplexValue
            printInfo.printSettings[NSPrintInfo.SettingKey("com_apple_print_PrintSettings_PMDuplexing")] = NSNumber(value: mode.printCoreValue)
            printInfo.dictionary()[NSPrintInfo.AttributeKey("com.apple.print.PrintSettings.PMDuplexing")] = NSNumber(value: mode.printCoreValue)
        }

        private func waitForPagination(in webView: WKWebView, attemptsRemaining: Int, completion: @escaping () -> Void) {
            webView.evaluateJavaScript("window.__printMDPaginated === true") { [weak self, weak webView] result, _ in
                guard let self else { return }

                if (result as? Bool) == true || attemptsRemaining <= 0 {
                    DispatchQueue.main.async(execute: completion)
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.waitForPagination(in: webView, attemptsRemaining: attemptsRemaining - 1, completion: completion)
                }
            }
        }

        private func presentPrintOperation(for webView: WKWebView, in window: NSWindow, printInfo: NSPrintInfo) {
            guard !isPresentingPrintPanel else { return }

            isPresentingPrintPanel = true

            let operation = webView.printOperation(with: printInfo)
            operation.showsPrintPanel = true
            operation.showsProgressPanel = true
            operation.canSpawnSeparateThread = true
            operation.runModal(for: window, delegate: self, didRun: #selector(Self.printOperationDidRun(_:success:contextInfo:)), contextInfo: nil)
        }

        @objc private func printOperationDidRun(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
            isPresentingPrintPanel = false
        }
    }
}

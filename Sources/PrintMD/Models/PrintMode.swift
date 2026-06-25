import AppKit

enum PrintMode: String, CaseIterable, Identifiable {
    case standard
    case eco

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "标准"
        case .eco:
            return "环保"
        }
    }

    var statusTitle: String {
        switch self {
        case .standard:
            return "打印模式：标准"
        case .eco:
            return "打印模式：环保，双面短边，每面 2 页"
        }
    }

    var printOrientation: NSPrintInfo.PaperOrientation {
        switch self {
        case .standard:
            return .portrait
        case .eco:
            return .landscape
        }
    }

    func effectiveDuplexMode(userSelection: PrintDuplexMode) -> PrintDuplexMode {
        switch self {
        case .standard:
            return userSelection
        case .eco:
            return .shortEdge
        }
    }
}

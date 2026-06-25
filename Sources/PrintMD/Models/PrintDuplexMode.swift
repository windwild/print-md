enum PrintDuplexMode: String, CaseIterable, Identifiable {
    case singleSided
    case longEdge
    case shortEdge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singleSided:
            return "单面"
        case .longEdge:
            return "双面-长边"
        case .shortEdge:
            return "双面-短边"
        }
    }

    var statusTitle: String {
        switch self {
        case .singleSided:
            return "打印方式：单面"
        case .longEdge:
            return "打印方式：双面长边翻页"
        case .shortEdge:
            return "打印方式：双面短边翻页"
        }
    }

    var printCoreValue: Int {
        switch self {
        case .singleSided:
            return 1
        case .longEdge:
            return 2
        case .shortEdge:
            return 3
        }
    }

    var ippSidesValue: String {
        switch self {
        case .singleSided:
            return "one-sided"
        case .longEdge:
            return "two-sided-long-edge"
        case .shortEdge:
            return "two-sided-short-edge"
        }
    }

    var cupsDuplexValue: String {
        switch self {
        case .singleSided:
            return "None"
        case .longEdge:
            return "DuplexNoTumble"
        case .shortEdge:
            return "DuplexTumble"
        }
    }
}

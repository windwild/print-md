import AppKit

enum PageSize: String, CaseIterable, Identifiable {
    case a4
    case letter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .a4:
            return "A4"
        case .letter:
            return "Letter"
        }
    }

    var statusTitle: String {
        "纸张：\(title)"
    }

    var cssSize: String {
        switch self {
        case .a4:
            return "210mm 297mm"
        case .letter:
            return "8.5in 11in"
        }
    }

    var cssWidth: String {
        switch self {
        case .a4:
            return "210mm"
        case .letter:
            return "8.5in"
        }
    }

    var cssHeight: String {
        switch self {
        case .a4:
            return "297mm"
        case .letter:
            return "11in"
        }
    }

    var paperSize: NSSize {
        switch self {
        case .a4:
            return NSSize(width: 595.28, height: 841.89)
        case .letter:
            return NSSize(width: 612, height: 792)
        }
    }

    var ecoScale: Double {
        let slotWidth = paperSize.height / 2
        let slotHeight = paperSize.width
        return min(slotWidth / paperSize.width, slotHeight / paperSize.height)
    }
}

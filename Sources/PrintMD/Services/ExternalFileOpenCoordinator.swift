import Foundation

@MainActor
final class ExternalFileOpenCoordinator {
    static let shared = ExternalFileOpenCoordinator()

    private var handler: ((URL) -> Void)?
    private var pendingURLs: [URL] = []

    private init() {}

    func installHandler(_ handler: @escaping (URL) -> Void) {
        self.handler = handler

        let urls = pendingURLs
        pendingURLs.removeAll()
        urls.forEach(handler)
    }

    func open(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        if let handler {
            urls.forEach(handler)
        } else {
            pendingURLs.append(contentsOf: urls)
        }
    }
}

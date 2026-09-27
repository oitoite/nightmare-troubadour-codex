import SwiftUI
import UIKit

/// Small image loader: memory cache + on-disk URLCache so card art and pack
/// art stay available offline once seen (the web app's service worker did this).
actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 32 * 1024 * 1024, diskCapacity: 512 * 1024 * 1024)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpAdditionalHeaders = ["User-Agent": "NTCodex/1.0 (iOS; card companion app)"]
        session = URLSession(configuration: config)
        cache.countLimit = 400
    }

    func image(for url: URL) async -> UIImage? {
        if let img = cache.object(forKey: url as NSURL) { return img }
        if let task = inFlight[url] { return await task.value }
        let task = Task<UIImage?, Never> {
            guard let result = try? await session.data(from: url) else { return nil }
            let (data, response) = result
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { return nil }
            guard let img = UIImage(data: data) else { return nil }
            return img
        }
        inFlight[url] = task
        let img = await task.value
        inFlight[url] = nil
        if let img { cache.setObject(img, forKey: url as NSURL) }
        return img
    }
}

/// Async image view backed by `ImageLoader`. Shows `placeholder` while loading
/// or when the fetch fails.
struct RemoteImage<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var failed = false

    init(url: URL?, contentMode: ContentMode = .fit, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            image = nil
            failed = false
            guard let url else { failed = true; return }
            let img = await ImageLoader.shared.image(for: url)
            if Task.isCancelled { return }
            image = img
            failed = img == nil
        }
    }
}

extension RemoteImage where Placeholder == Color {
    init(url: URL?, contentMode: ContentMode = .fit) {
        self.init(url: url, contentMode: contentMode) { Color.clear }
    }
}

import UIKit

class ImageCache {
    static let shared = ImageCache()
    private init() {}

    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cached = cachedImage(urlString: urlString) {
            completion(cached)
            return
        }

        guard let url = URL(string: urlString) else { completion(nil); return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            self.saveToCache(image: image, urlString: urlString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    private func cachedImage(urlString: String) -> UIImage? {
        let fileURL = localURL(for: urlString)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private func saveToCache(image: UIImage, urlString: String) {
        guard let data = image.pngData() else { return }
        let fileURL = localURL(for: urlString)
        try? data.write(to: fileURL)
    }

    private func localURL(for urlString: String) -> URL {
        let filename = urlString.split(separator: "/").last ?? "unknown.png"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(String(filename))
    }
}

//
//  ImageCache.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import UIKit

// MARK: - Image Cache Manager
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private var runningRequests = [UUID: URLSessionDataTask]()

    private init() {}

    func loadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) -> UUID? {
        let key = url.absoluteString as NSString

        if let cachedImage = cache.object(forKey: key) {
            completion(.success(cachedImage))
            return nil
        }

        let uuid = UUID()

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            defer { self?.runningRequests.removeValue(forKey: uuid) }

            if let error = error {
                guard (error as NSError).code != NSURLErrorCancelled else { return }
                completion(.failure(error))
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(ImageError.invalidData))
                return
            }

            self?.cache.setObject(image, forKey: key)
            completion(.success(image))
        }

        task.resume()
        runningRequests[uuid] = task
        return uuid
    }

    func cancelLoad(_ uuid: UUID) {
        runningRequests[uuid]?.cancel()
        runningRequests.removeValue(forKey: uuid)
    }

    enum ImageError: Error {
        case invalidData
        case invalidURL
    }
}

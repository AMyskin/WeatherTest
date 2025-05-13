//
//  UIImageView+extension.swift
//  WeatherTest
//
//  Created by Alexander Myskin on 13.05.2025.
//

import UIKit

// MARK: - UIImageView Extension
extension UIImageView {
    private static var taskKey = 0
    private var currentTask: UUID? {
        get { objc_getAssociatedObject(self, &UIImageView.taskKey) as? UUID }
        set { objc_setAssociatedObject(self, &UIImageView.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func load(from urlString: String, placeholder: UIImage? = nil) {
        var fixedString = urlString
        if !fixedString.hasPrefix("http") {
            fixedString = "https:" + fixedString
        }

        guard let url = URL(string: fixedString) else {
            image = placeholder
            return
        }

        image = placeholder

        if let currentTask = currentTask {
            ImageCache.shared.cancelLoad(currentTask)
        }

        let task = ImageCache.shared.loadImage(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.image = image
                case .failure(let error):
                    print("Image load error: \(error.localizedDescription)")
                    self?.image = placeholder
                }
            }
        }

        currentTask = task
    }

    func cancelImageLoad() {
        if let currentTask = currentTask {
            ImageCache.shared.cancelLoad(currentTask)
            self.currentTask = nil
        }
    }
}

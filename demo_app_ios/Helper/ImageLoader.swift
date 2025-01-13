//
//  ImageLoader.swift
//  demo_app_ios
//
//  Created by 김민식 on 4/24/24.
//

import UIKit

class ImageLoader {
    static func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Could not decode image")
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}

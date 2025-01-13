//
//  PlacementCell.swift
//  demo_app_ios
//
//  Created by 10004 on 4/24/24.
//

import UIKit

class PlacementCell: UICollectionViewCell {
    
    static let cellName = "PlacementCell"
    static let cellReuseIdentifier = "PlacementCell"

    @IBOutlet weak var thumbnailImage: UIImageView!
    @IBOutlet weak var sellerLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(_ item: AdvertisementItem) {
        nameLabel.text = item.name
        priceLabel.text = "\(item.price)원"
        sellerLabel.text = item.summary
        
        guard let url = URL(string: item.image) else { return }
        
        ImageLoader.loadImage(from: url) { [weak self] image in
            DispatchQueue.main.async {
                self?.thumbnailImage.image = image
            }
        }
    }
}

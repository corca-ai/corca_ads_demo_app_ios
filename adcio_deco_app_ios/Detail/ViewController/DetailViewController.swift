//
//  DetailViewController.swift
//  adcio_deco_app_ios
//
//  Created by 김민식 on 4/24/24.
//

import UIKit

class DetailViewController: UIViewController {
    static let identifier = "DetailViewControllerIdentifer"
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var sellerLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    private var suggestion: SuggestionEntity?
    private var presenter: DetailPresenter?
    private let userAgent: String = "\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)"
    private let appVersion: String? = {
        if let info: [String: Any] = Bundle.main.infoDictionary,
           let currentVersion: String = info["CFBundleShortVersionString"] as? String {
            return currentVersion
        }
        return nil
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let suggestion else { return }
        presenter = DetailPresenter(suggestion: suggestion,
                                    view: self,
                                    userAgent: userAgent,
                                    appVersion: appVersion ?? ""
        )
        
        self.navigationItem.title = presenter?.name() ?? ""
        guard let url = URL(string: presenter?.thumbnailImage() ?? "") else { return }
        
        ImageLoader.loadImage(from: url) { [weak self] image in
            DispatchQueue.main.async {
                self?.thumbnailImageView.image = image
            }
        }
    
        nameLabel.text = presenter?.name()
        priceLabel.text = "\(presenter?.price() ?? 0)₩"
        sellerLabel.text = presenter?.seller()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        onView(with: "Deatil")
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func configure(_ suggestion: SuggestionEntity, completion: () -> Void) {
        self.suggestion = suggestion
        completion()
    }
    
    @IBAction func purchaseButtonTapped(_ sender: UIButton) {
        onPurchase()
    }
    
    @IBAction func addCartButtonTapped(_ sender: UIBarButtonItem) {
        onAddToCart()
    }
}

extension DetailViewController: DetailPresenterView {
    func onView(with path: String) {
        DispatchQueue.main.async {
            self.presenter?.onView(with: path)
        }
    }
    
    func onAddToCart() {
        DispatchQueue.main.async {
            self.presenter?.onAddToCart()
        }
    }
    
    func onPurchase() {
        DispatchQueue.main.async {
            self.presenter?.onPurchase()
        }
    }
}

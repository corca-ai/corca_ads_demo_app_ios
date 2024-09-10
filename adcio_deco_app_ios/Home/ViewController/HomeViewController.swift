//
//  HomeViewController.swift
//  adcio_deco_app_ios
//
//  Created by 10004 on 4/23/24.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var presenter: HomePresenter?
    private var visibleCellsWorkItems: [IndexPath: DispatchWorkItem] = [:]
    private let impressionThreshold: TimeInterval = 1.0
    private let userAgent: String = "\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)"
    private let appVersion: String? = {
        if let info: [String: Any] = Bundle.main.infoDictionary,
           let currentVersion: String = info["CFBundleShortVersionString"] as? String {
            return currentVersion
        }
        return nil
    }()
    private var isLoadingMoreData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = HomePresenter(view: self,
        userAgent: userAgent,
        appVersion: appVersion ?? "")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        registerXib()
        
        presenter?.reloadCollectionView = { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                self?.isLoadingMoreData = false
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createRecommendationProducts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupWorkItems()
    }
    
    private func registerXib() {
        let nibName = UINib(nibName: PlacementCell.cellName,
                            bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: PlacementCell.cellReuseIdentifier)
    }
    
    // MARK: - Code to detect if a product is more than 50% visible on screen and visible for more than 1 second
    private func checkVisibleCells() {
        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame
                let visibleRect = CGRect(
                    x: collectionView.contentOffset.x,
                    y: collectionView.contentOffset.y,
                    width: collectionView.bounds.size.width,
                    height: collectionView.bounds.size.height
                )
                
                guard let suggestion = presenter?.suggestions[indexPath.item] else { return }
                
                if let cellFrame = cellFrame, visibleRect.intersects(cellFrame) {
                    let intersection = visibleRect.intersection(cellFrame)
                    let visibleArea = intersection.width * intersection.height
                    let cellArea = cellFrame.width * cellFrame.height
                    
                    if visibleArea / cellArea >= 0.5 {
                        scheduleImpression(for: indexPath, logOption: suggestion.option)
                    } else {
                        cancelScheduledImpression(for: indexPath)
                    }
                } else {
                    cancelScheduledImpression(for: indexPath)
                }
            }
        }
    }
    
    private func scheduleImpression(for indexPath: IndexPath, logOption: LogOptionEntity) {
        if visibleCellsWorkItems[indexPath] != nil { return }
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.onImpression(with: logOption)
            self?.visibleCellsWorkItems[indexPath] = nil
        }
        visibleCellsWorkItems[indexPath] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + impressionThreshold, execute: workItem)
    }
    
    private func cancelScheduledImpression(for indexPath: IndexPath) {
        if let workItem = visibleCellsWorkItems[indexPath] {
            workItem.cancel()
            visibleCellsWorkItems[indexPath] = nil
        }
    }
    
    private func cleanupWorkItems() {
        for workItem in visibleCellsWorkItems.values {
            workItem.cancel()
        }
        visibleCellsWorkItems.removeAll()
    }
    
    private func loadMoreData() {
        guard !isLoadingMoreData else { return }
        isLoadingMoreData = true
        createRecommendationProducts()
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter?.suggestions.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: PlacementCell = collectionView.dequeueReusableCell(withReuseIdentifier: PlacementCell.cellReuseIdentifier,
                                                                           for: indexPath) as? PlacementCell else { return UICollectionViewCell() }
        
        guard let suggestion = presenter?.suggestions[indexPath.item] else { return UICollectionViewCell() }
        cell.configure(suggestion)
        checkVisibleCells()
        
        return cell
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let suggestion = presenter?.suggestions[indexPath.item] else { return }
        onClick(suggestion)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailViewController = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return
        }
        
        detailViewController.configure(suggestion) { [weak self] in
            self?.navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        checkVisibleCells()
        if let presenter = presenter {
            let contentHeight = scrollView.contentSize.height
            let offsetY = scrollView.contentOffset.y
            let scrollViewHeight = scrollView.frame.size.height
            
            if offsetY > contentHeight - scrollViewHeight * 2 {
                let visibleCells = collectionView.visibleCells
                let indexPaths = visibleCells.compactMap { collectionView.indexPath(for: $0) }
                if indexPaths.contains(where: { $0.item == presenter.suggestions.count - 2 }) {
                    loadMoreData()
                }
            }
        }
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 140, height: 240)
    }
}

extension HomeViewController: HomePresenterView {
    func onImpression(with option: LogOptionEntity) {
        presenter?.onImpression(with: option)
    }
    
    func onClick(_ suggestion: SuggestionEntity) {
        presenter?.onClick(suggestion)
    }
    
    func createAdvertisementProducts() {
        presenter?.createAdvertisementProducts()
    }
    
    func createRecommendationProducts() {
        presenter?.createRecommendationProducts()
    }
    
    func createAdvertisementBanners() {
        presenter?.createAdvertisementBanners()
    }
    
    func createRecommendationBanners() {
        presenter?.createRecommendationBanners()
    }
}

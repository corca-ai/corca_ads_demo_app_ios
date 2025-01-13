//
//  HomeViewController.swift
//  demo_app_ios
//
//  Created by 10004 on 4/23/24.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var presenter: HomePresenter?
    private var visibleCellsWorkItems: [IndexPath: DispatchWorkItem] = [:]
    private let impressionThreshold: TimeInterval = 1.0
    private let storeID = "7bbb703e-a30b-4a4a-91b4-c0a7d2303415"
    private let userAgent: String = "\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)"
    
    private let appVersion: String? = {
        if let info: [String: Any] = Bundle.main.infoDictionary,
           let currentVersion: String = info["CFBundleShortVersionString"] as? String {
            return currentVersion
        }
        return nil
    }()
    
    private var isLoadingMoreData = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = HomePresenter(view: self, appVersion: appVersion ?? "")
        
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
        Task {
            await createAdvertisementProducts()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupWorkItems()
    }
    
    private func registerXib() {
        let nibName = UINib(nibName: PlacementCell.cellName, bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: PlacementCell.cellReuseIdentifier)
    }
    
    // 기준1. 관찰 대상의 50% 이상이 뷰포트에 보여야 합니다.
    private func checkVisibleCells() {
        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell),
               let adProducts = presenter?.advertisementProducts,
               indexPath.item < adProducts.count
            {
                let cellFrame = collectionView.layoutAttributesForItem(at: indexPath)?.frame
                let visibleRect = CGRect(
                    x: collectionView.contentOffset.x,
                    y: collectionView.contentOffset.y,
                    width: collectionView.bounds.size.width,
                    height: collectionView.bounds.size.height
                )
                
                guard let cellFrame = cellFrame else { continue }
                
                let intersection = visibleRect.intersection(cellFrame)
                let visibleArea = intersection.width * intersection.height
                let cellArea = cellFrame.width * cellFrame.height
                
                if visibleArea / cellArea >= 0.5 {
                    scheduleImpression(for: indexPath,
                                       advertisementProduct: adProducts[indexPath.item])
                } else {
                    cancelScheduledImpression(for: indexPath)
                }
            }
        }
    }
    
    private func scheduleImpression(for indexPath: IndexPath,
                                    advertisementProduct: AdvertisementItem) {
        // 기준3. 이미 기록된 상품은 재기록하지 않습니다.
        if visibleCellsWorkItems[indexPath] != nil {
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
        
            self.onImpression(
                appVersion: self.appVersion,
                storeId: self.storeID,
                customerId: nil,
                requestId: advertisementProduct.requestId,
                adsetId: advertisementProduct.adsetId
            )
        
            self.visibleCellsWorkItems[indexPath] = nil
        }
        
        visibleCellsWorkItems[indexPath] = workItem
        
        // 기준2. 1초 이상 observe된 상품만 기록됩니다.
        DispatchQueue.main.asyncAfter(deadline: .now() + impressionThreshold,
                                      execute: workItem)
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
    
    private func loadMoreData() async {
        guard !isLoadingMoreData else { return }
        isLoadingMoreData = true
        await createAdvertisementProducts()
    }
}

// MARK: - UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        return presenter?.advertisementProducts.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PlacementCell.cellReuseIdentifier,
            for: indexPath
        ) as? PlacementCell else {
            return UICollectionViewCell()
        }
        
        if let adProducts = presenter?.advertisementProducts,
           indexPath.item < adProducts.count
        {
            cell.configure(adProducts[indexPath.item])
        }
        
        checkVisibleCells()
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath)
    {
        guard let adProducts = presenter?.advertisementProducts,
              indexPath.item < adProducts.count
        else { return }
        
        let item = adProducts[indexPath.item]
        
        onClick(
            appVersion: appVersion,
            storeId: storeID,
            customerId: nil,
            requestId: item.requestId,
            adsetId: item.adsetId
        )
        
        // TODO: push or present detail view
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
                if indexPaths.contains(where: { $0.item == presenter.advertisementProducts.count - 2 }) {
                    Task {
                        await loadMoreData()
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: 140, height: 240)
    }
}

// MARK: - HomePresenterView
extension HomeViewController: HomePresenterView {
    func createAdvertisementProducts() async {
        await presenter?.createAdvertisementProducts()
    }
    
    func onImpression(
        appVersion: String?,
        storeId: String,
        customerId: String?,
        requestId: String,
        adsetId: String
    ) {
        presenter?.onImpression(
            appVersion: appVersion,
            storeId: storeId,
            customerId: customerId ?? "",
            requestId: requestId,
            adsetId: adsetId
        )
    }
    
    func onClick(
        appVersion: String?,
        storeId: String,
        customerId: String?,
        requestId: String,
        adsetId: String
    ) {
        presenter?.onClick(
            appVersion: appVersion,
            storeId: storeId,
            customerId: customerId,
            requestId: requestId,
            adsetId: adsetId
        )
    }
}

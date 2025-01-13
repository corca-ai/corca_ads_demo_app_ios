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
    
    /// - key: IndexPath(어느 셀인지)
    /// - value: DispatchWorkItem (1초 후 onImpression 호출을 담당)
    private var visibleCellsWorkItems: [IndexPath: DispatchWorkItem] = [:]
    
    /// 1초 이상 노출 시 Impression을 찍기 위해 1초 스케줄
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
    
    // MARK: - Private Methods
    
    /// nib 등록
    private func registerXib() {
        let nibName = UINib(nibName: PlacementCell.cellName, bundle: nil)
        collectionView.register(nibName, forCellWithReuseIdentifier: PlacementCell.cellReuseIdentifier)
    }
    
    /// 셀이 50% 이상 노출되었는지, 1초 이상 유지되었는지 확인
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
                
                // 화면에 실제로 보이는 영역과 셀의 영역 교집합 구함
                let intersection = visibleRect.intersection(cellFrame)
                let visibleArea = intersection.width * intersection.height
                let cellArea = cellFrame.width * cellFrame.height
                
                // 50% 이상 노출 여부
                if visibleArea / cellArea >= 0.5 {
                    // 만약 50% 이상 노출되면 '1초 뒤에' onImpression 호출을 스케줄링
                    scheduleImpression(for: indexPath,
                                       advertisementProduct: adProducts[indexPath.item])
                } else {
                    // 50% 미만으로 내려가면 기존에 스케줄링된 onImpression 취소
                    cancelScheduledImpression(for: indexPath)
                }
            }
        }
    }
    
    /// 1초 뒤 onImpression 호출을 스케줄링
    private func scheduleImpression(for indexPath: IndexPath,
                                    advertisementProduct: AdvertisementItem) {
        // 이미 스케줄링 중이라면 중복으로 스케줄 X
        if visibleCellsWorkItems[indexPath] != nil {
            return
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // onImpression 호출
            self.onImpression(
                appVersion: self.appVersion,
                storeId: self.storeID,
                customerId: nil,
                requestId: advertisementProduct.requestId,
                adsetId: advertisementProduct.adsetId
            )
            // 스케줄링 목록에서 제거
            self.visibleCellsWorkItems[indexPath] = nil
        }
        
        visibleCellsWorkItems[indexPath] = workItem
        
        // 1초 후 실행 (impressionThreshold 초)
        DispatchQueue.main.asyncAfter(deadline: .now() + impressionThreshold,
                                      execute: workItem)
    }
    
    /// 스케줄링된 1초 뒤 onImpression 호출을 취소
    private func cancelScheduledImpression(for indexPath: IndexPath) {
        if let workItem = visibleCellsWorkItems[indexPath] {
            workItem.cancel()
            visibleCellsWorkItems[indexPath] = nil
        }
    }
    
    /// 화면을 떠나면 WorkItem 전체 정리
    private func cleanupWorkItems() {
        for workItem in visibleCellsWorkItems.values {
            workItem.cancel()
        }
        visibleCellsWorkItems.removeAll()
    }
    
    /// 무한 스크롤 시 데이터 로드
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
        
        // 셀이 로드될 때마다 한 번씩 체크 → 매번 cellForItemAt에서 call
        // (추가적으로 scrollViewDidScroll에서 호출해도 됨)
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
        // 스크롤할 때마다 50% 노출 체크
        checkVisibleCells()
        
        // 무한 스크롤 체크
        if let presenter = presenter {
            let contentHeight = scrollView.contentSize.height
            let offsetY = scrollView.contentOffset.y
            let scrollViewHeight = scrollView.frame.size.height
            
            // 임의로 scrollViewHeight * 2 지점에서 추가 로드
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

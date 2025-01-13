//
//  HomePresenter.swift
//  demo_app_ios
//
//  Created by 10004 on 4/24/24.
//

import Foundation

protocol HomePresenterView: AnyObject {
    func createAdvertisementProducts() async
    
    func onClick(
        appVersion: String?,
        storeId: String,
        customerId: String?,
        requestId: String,
        adsetId: String
    )
    
    func onImpression(
        appVersion: String?,
        storeId: String,
        customerId: String?,
        requestId: String,
        adsetId: String
    )
}

final class HomePresenter {
    private let clientID: String = "7bbb703e-a30b-4a4a-91b4-c0a7d2303415"
    private var analyticsManager: AnalyticsViewManageable
    //Impression은 화면이 실행된 후 한 번만 실행되어야 합니다.  이 로직은 임프레션이 여러 번 호출되는 것을 방지합니다.
    private var impressionManager: ImpressionManageable
    private(set) var advertisementProducts: [AdvertisementItem] = [] {
        didSet {
            self.reloadCollectionView?()
        }
    }
    private var excludingProductIDs: [String] = ["458007", "1211423", "1165080", "182602"]
    private var baselineProductIDs = [String]()
    
    
    weak var view: HomePresenterView?
    var reloadCollectionView: (() -> Void)?
    
    init(view: HomePresenterView, appVersion: String) {
        self.analyticsManager = AnalyticsViewManager(clientID: "clientID")
        self.impressionManager = ImpressionManager()
        self.view = view
    }
    
    func onClick(
        appVersion: String?,
        storeId: String,
        customerId: String?,
        requestId: String,
        adsetId: String
    ) {
        Task {
            let result = await analyticsManager.onClick(
                appVersion: appVersion,
                storeId: storeId,
                customerId: customerId,
                requestId: requestId,
                adsetId: adsetId)
            switch result {
            case .success:
                print("onClick ✅")
            case .failure(let error):
                print("onClick ❌ : \(error)")
            }
        }
    }
    
    func onImpression(
        appVersion: String?,
        storeId: String,
        customerId: String,
        requestId: String,
        adsetId: String) {
            guard !impressable(with: adsetId) else {
                return
            }
            
            append(with: adsetId)
            
            Task {
                let result = await analyticsManager.onImpression(
                    appVersion: appVersion,
                    storeId: storeId,
                    customerId: customerId,
                    requestId: requestId,
                    adsetId: adsetId)
                
                switch result {
                case .success:
                    print("onImpression ✅")
                case .failure(let error):
                    print("onImpression ❌ : \(error)")
                }
            }
        }
    
    func createAdvertisementProducts() async {
        let result = await analyticsManager.createAdvertisementProducts(customerId: nil,
                                                           placementId: "0eae4a71-a99f-44db-8aea-4a8d7e06fc41",
                                                           covisitationBaseProductIds: nil,
                                                           audience: nil)
        
        switch result {
        case .success(let response):
            print("createAdvertisementProducts ✅")
            self.advertisementProducts = response
        case .failure(let error):
            print("createAdvertisementProducts ❌ : \(error)")
        }
    }
    
    private func impressable(with adSetID: AdSetID) -> Bool {
        return impressionManager.impressable(with: adSetID)
    }
    
    private func append(with adSetID: AdSetID) {
        impressionManager.append(with: adSetID)
    }
}

//
//  HomePresenter.swift
//  adcio_deco_app_ios
//
//  Created by 10004 on 4/24/24.
//

import Foundation

import AdcioAnalytics
import AdcioPlacement
import ControllerV1
import Amplitude

protocol HomePresenterView: AnyObject {
    func onClick(_ suggestion: SuggestionEntity)
    func onImpression(with option: LogOptionEntity)
    func createAdvertisementProducts()
    func createRecommendationProducts()
    func createAdvertisementBanners()
    func createRecommendationBanners()
}

final class HomePresenter {
    private let clientID: String = "7bbb703e-a30b-4a4a-91b4-c0a7d2303415"
    private var analyticsManager: AnalyticsViewManageable
    private var placementManager: PlacementManageable
    //Impression should only run once after the screen is launched.  This logic prevents Impression from being called multiple times.
    private var impressionManager: ImpressionManageable
    private(set) var suggestions: [SuggestionEntity] = [] {
        didSet {
            self.reloadCollectionView?()
        }
    }
    private var excludingProductIDs: [String] = ["458007", "1211423", "1165080", "182602"]
    private var baselineProductIDs = [String]()
    
    
    weak var view: HomePresenterView?
    var reloadCollectionView: (() -> Void)?
    
    init(view: HomePresenterView, userAgent: String?, appVersion: String) {
        self.analyticsManager = AnalyticsManager(clientID: clientID, userAgent: userAgent, appVersion: appVersion)
        self.placementManager = PlacementManager(userAgent: userAgent, appVersion: appVersion)
        self.impressionManager = ImpressionManager()
        self.view = view
    }
    
    func onClick(_ suggestion: SuggestionEntity) {
        Amplitude.instance().logEvent("onClick")
        guard suggestion.product.isAd else { return }
        
        let option = LogOptionMapper.map(from: suggestion.option)
        
        analyticsManager.onClick(option: option,
                                 customerID: nil,
                                 productIDOnStore: suggestion.product.id
        ) { result, error in
            guard error == nil else {
                print("onClick ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("onClick ❌")
                return
            }
            
            print("onClick ✅")
        }
    }
    
    func onImpression(with option: LogOptionEntity) {
        guard !impressable(with: option.adsetID) else {
            return
        }
        
        append(with: option.adsetID)
        
        let optionEntity = LogOptionMapper.map(from: option)
        Amplitude.instance().logEvent("onImpression")
        analyticsManager.onImpression(option: optionEntity,
                                      customerID: nil,
                                      productIDOnStore: nil) { result, error in
            guard error == nil else {
                print("onImpression ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("onImpression ❌")
                return
            }
            
            print("onImpression ✅")
        }
    }
    
    /// create Advertisement Products method
    func createAdvertisementProducts() {
        Amplitude.instance().logEvent("AdvertisementProducts")
        placementManager.createAdvertisementProducts(
            clientID: clientID,
            excludingProductIDs: excludingProductIDs,
            categoryID: nil,
            placementID: "767dc293-fa9d-48fa-a3b4-429ccc4ee8fe",
            customerID: nil,
            fromAgent: false,
            baselineProductIDs: baselineProductIDs,
            filters: nil,
            targets: [
                SuggestionRequestTarget(keyName: "gender", values: ["male"]),
                SuggestionRequestTarget(keyName: "age", values: ["20s"])
            ]
        )
        { [weak self] result, error in
            guard let error else {
                print("createAdvertisementProducts ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("products is nil ❌")
                return
            }
            
            let suggestions = SuggestionMapper.map(from: result)
            self?.suggestions.append(contentsOf: suggestions.map { $0 })
            self?.excludingProductIDs.append(contentsOf: self?.suggestions.compactMap { $0.product.idOnStore } ?? [])
            print("createAdvertisementProducts ✅")
        }
    }
    
    /// create Advertisement Banners method
    func createAdvertisementBanners() {
        Amplitude.instance().logEvent("AdvertisementBanners")
        placementManager.createAdvertisementBanners(
            clientID: clientID,
            excludingProductIDs: nil,
            categoryID: nil,
            placementID: "placementID",
            customerID: "customerID",
            fromAgent: false,
            targets: []
        )
        { [weak self] result, error in
            guard error == nil else {
                print("createAdvertisementBanners ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("banner is nil ❌")
                return
            }
            
            //success
            print("createAdvertisementBanners ✅")
        }
    }
    
    /// create Recommendation Products method
    func createRecommendationProducts() {
        Amplitude.instance().logEvent("RecommendationProducts")
        placementManager.createRecommendationProducts(
            clientID: clientID,
            excludingProductIDs: excludingProductIDs,
            categoryID: nil,
            placementID: "e97f9b4b-91ac-4835-a1f7-3098b9868f69",
            customerID: nil,
            fromAgent: false,
            baselineProductIDs: baselineProductIDs,
            filters: nil,
            targets: [
                SuggestionRequestTarget(keyName: "gender", values: ["male"])
            ]
        )
        { [weak self] result, error in
            guard error == nil else {
                print("createRecommendationProducts ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("products is nil ❌")
                return
            }
            
            let suggestions = SuggestionMapper.map(from: result)
            self?.suggestions.append(contentsOf: suggestions.map { $0 })
            self?.excludingProductIDs.append(contentsOf: self?.suggestions.compactMap { $0.product.idOnStore } ?? [])
            print("createRecommendationProducts ✅")
        }
    }
    
    /// create Recommendation Bannders method
    func createRecommendationBanners() {
        Amplitude.instance().logEvent("RecommendationBanners")
        placementManager.createRecommendationBanners(
            clientID: clientID,
            excludingProductIDs: nil,
            categoryID: nil,
            placementID: "placementID",
            customerID: "customerID",
            fromAgent: false,
            targets: []
        )
        { [weak self] result, error in
            guard error == nil else {
                print("createRecommendationBanners ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("banner is nil ❌")
                return
            }
            
            //success
            print("createRecommendationBanners ✅")
        }
    }
    
    private func impressable(with adSetID: AdSetID) -> Bool {
        return impressionManager.impressable(with: adSetID)
    }
    
    private func append(with adSetID: AdSetID) {
        impressionManager.append(with: adSetID)
    }
}

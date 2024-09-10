//
//  DetailPresenter.swift
//  adcio_deco_app_ios
//
//  Created by 김민식 on 4/24/24.
//

import Foundation
import AdcioAnalytics
import Amplitude

protocol DetailPresenterView: AnyObject {
    func onView(with path: String)
    func onAddToCart()
    func onPurchase()
}

final class DetailPresenter {
    private let clientID: String = "7bbb703e-a30b-4a4a-91b4-c0a7d2303415"
    private var analyticsManager: AnalyticsProductManageable
    private(set) var suggestion: SuggestionEntity
    
    weak var view: DetailPresenterView?
    
    init(suggestion: SuggestionEntity, view: DetailPresenterView, userAgent: String?, appVersion: String
    ) {
        self.analyticsManager = AnalyticsManager(clientID: clientID,
                                                 userAgent: userAgent,
                                                 appVersion: appVersion)
        self.suggestion = suggestion
        self.view = view
    }
    
    func thumbnailImage() -> String {
        return suggestion.product.image
    }
    
    func seller() -> String {
        return suggestion.product.seller
    }
    
    func name() -> String {
        return suggestion.product.name
    }
    
    func price() -> Double {
        return suggestion.product.price
    }
    
    func identifier() -> String {
        return suggestion.product.id
    }
    
    func onView(with path: String) {
        Amplitude.instance().logEvent("onView")
        analyticsManager.onView(customerID: nil,
                                productIDOnStore: suggestion.product.id,
                                requestID: suggestion.option.requestID,
                                adsetID: suggestion.option.adsetID,
                                categoryIDOnStore: nil
        ) { result, error in
            guard error == nil else {
                print("onView ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("onView ❌")
                return
            }
            
            print("onView ✅")
        }
    }
    
    func onAddToCart() {
        Amplitude.instance().logEvent("onAddToCart")
        analyticsManager.onAddToCart(cartID: nil,
                                     customerID: nil,
                                     productIDOnStore: suggestion.product.id,
                                     requestID: suggestion.option.requestID,
                                     adsetID: suggestion.option.adsetID,
                                     categoryIdOnStore: nil,
                                     quantity: nil
        ) { result, error in
            guard error == nil else {
                print("onAddToCart ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("onAddToCart ❌")
                return
            }
            
            print("onAddToCart ✅")
        }
    }
    
    func onPurchase() {
        Amplitude.instance().logEvent("onPurchase")
        analyticsManager.onPurchase(orderID: "orderID",
                                    customerID: nil,
                                    requestID: suggestion.option.requestID,
                                    adsetID: suggestion.option.adsetID,
                                    categoryIDOnStore: nil,
                                    quantity: nil,
                                    productIDOnStore: suggestion.product.id,
                                    amount: suggestion.product.price
        ) { result, error in
            guard error == nil else {
                print("onPurchase ❌ : \(error)")
                return
            }
            
            guard let result else {
                print("onPurchase ❌")
                return
            }
            
            print("onPurchase ✅")
        }
    }
}

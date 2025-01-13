//
//  Mapper.swift
//  demo_app_ios
//
//  Created by 10004 on 4/23/24.
//

import Foundation

struct SuggestionMapper {
    static func map(from: ProductSuggestionResponseDto) -> [SuggestionEntity] {
        let isBaseline = from.metadata.isBaseline
        let products = from.suggestions.map { $0.product }
        let options = from.suggestions.map { $0.logOptions }
        
        let suggestions = zip(products, options).map { product, option in
            let productEntity = ProductEntity(id: product.id, 
                                              idOnStore: product.idOnStore,
                                              name: product.name,
                                              image: product.image,
                                              price: product.price,
                                              seller: product.sellerId,
                                              isAd: true)
            
            let optionEntity = LogOptionEntity(requestID: option.requestId,
                                               adsetID: option.adsetId)
            
            return SuggestionEntity(product: productEntity, option: optionEntity, isBaseline: isBaseline)
        }
        
        return suggestions
    }
}

struct LogOptionMapper {
    static func map(from: LogOptionEntity) -> AdcioLogOption {
        let option = AdcioLogOption(requestID: from.requestID,
                                    adsetID: from.adsetID)
        return option
    }
}

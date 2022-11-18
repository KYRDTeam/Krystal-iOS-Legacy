//
//  EarnParamBuilderFactory.swift
//  EarnModule
//
//  Created by Tung Nguyen on 15/11/2022.
//

import Foundation
import Services

class EarnParamBuilderFactory {
    
    static func create(platform: SpecifiedEarningPlatform) -> EarnParamBuilder {
        switch platform {
        case .ankr:
            return AnkrParamBuilder()
        case .lido:
            return LidoParamBuilder()
        case .other:
            return CommonParamBuilder()
        }
    }
    
}

//
//  StakingValidationError.swift
//  EarnModule
//
//  Created by Tung Nguyen on 11/11/2022.
//

import Foundation

enum StakingValidationError {
    case empty
    case insufficient
    case notEnoughMin(minValue: Double)
    case higherThanMax(maxValue: Double)
    case notIntervalOf(interval: Double)
}

//
//  Constants.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 31/10/2022.
//

import Foundation
import BigInt

class Constants {
    static let lowestGasLimit = BigInt(21_000)
    static let defaultGasLimit = BigInt(120_000)
    static let helpIcon = UIImage(named: "help_icon_large", in: Bundle(for: Constants.self), compatibleWith: nil)!
}

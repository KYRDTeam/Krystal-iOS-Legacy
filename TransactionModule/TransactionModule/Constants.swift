//
//  Constants.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 31/10/2022.
//

import Foundation
import BigInt

class Images {
    static let helpIcon = UIImage(named: "help_icon_large", in: Bundle(for: Images.self), compatibleWith: nil)!
}

public class TransactionConstants {
    public static let lowestGasLimit = BigInt(21_000)
    public static let defaultGasLimit = BigInt(180_000)
    public static let oneGWei = BigInt(10).power(9)
    public static let maxTokenAmount = BigInt(2).power(256) - BigInt(1)
}

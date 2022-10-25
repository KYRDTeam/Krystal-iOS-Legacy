//
//  ApprovedTokenItemViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import UIKit

class ApprovedTokenItemViewModel {
    var symbol: String
    var tokenIcon: String
    var chainIcon: UIImage
    var tokenName: String
    var isVerified: Bool
    var spenderAddress: String
    var amount: String
    
    init() {
        symbol = ""
        tokenIcon = ""
        chainIcon = UIImage()
        tokenName = ""
        isVerified = false
        spenderAddress = ""
        amount = ""
    }
}

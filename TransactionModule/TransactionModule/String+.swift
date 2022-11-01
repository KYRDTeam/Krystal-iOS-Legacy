//
//  String+.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 28/10/2022.
//

import Foundation

extension String {
    
    func toBeLocalised() -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle(for: TransactionSettingPopup.self), value: "", comment: "")
    }
    
}

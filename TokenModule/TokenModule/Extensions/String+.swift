//
//  String+.swift
//  TokenModule
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

extension String {
  func toBeLocalised() -> String {
      return NSLocalizedString(self, tableName: nil, bundle: TokenModule.bundle, value: "", comment: "")
  }
}

//
//  ValidationResult.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 14/04/2022.
//

import Foundation

enum ValidationResult<ErrorType> {
  case success
  case failure(error: ErrorType)
}

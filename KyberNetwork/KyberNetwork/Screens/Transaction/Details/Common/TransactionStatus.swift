//
//  TransactionStatus.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 18/05/2022.
//

import Foundation

enum TransactionStatus {
  case success
  case failure
  case pending
  case other(title: String)
  
  init(status: String) {
    switch status.lowercased() {
    case "success":
      self = .success
    case "failure", "failed":
      self = .failure
    case "pending":
      self = .pending
    default:
      self = .other(title: status)
    }
  }
  
}

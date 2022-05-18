//
//  TransactionStatus.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 18/05/2022.
//

import Foundation

enum TransactionStatus: String {
  case success = "success"
  case failure = "failure"
  case pending = "pending"
  case unknown
  
  init(status: String) {
    self = TransactionStatus(rawValue: status.lowercased()) ?? .unknown
  }
  
}

//
//  SolanaTransactionStorage.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

class SolanaTransactionStorage {
  
  let userDefaults = UserDefaults.standard
  
  let keyFormat = "CACHED_SOLANA_TRANSACTIONS_%@"
  
  func getSolanaTransactions(address: String) -> [SolanaTransaction] {
    let key = String(format: keyFormat, address)
    if let data = userDefaults.object(forKey: key) as? Data {
      if let transactions = try? JSONDecoder().decode([SolanaTransactionObject].self, from: data) {
        return transactions.map { $0.toDomain() }
      }
    }
    return []
  }
  
  func saveTransactions(address: String, transactions: [SolanaTransaction]) {
    let key = String(format: keyFormat, address)
    let encoder = JSONEncoder()
    let transactionObjects = transactions.map(SolanaTransactionObject.init)
    if let encoded = try? encoder.encode(transactionObjects) {
      userDefaults.set(encoded, forKey: key)
    }
  }
  
}

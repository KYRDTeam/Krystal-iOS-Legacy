//
//  SolanaSerumService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 15/06/2022.
//

import Foundation
import Moya
import BigInt

class SolanaSerumService {
  
  func getMinimumBalanceForRentExemption(completion: @escaping (Int?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.getMinimumBalanceForRentExemption) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let result = json["result"] as? Int {
           completion(result)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
      }
  }

  func getRecentBlockhash(completion: @escaping (String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.getRecentBlockhash) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJson = resultJson["value"] as? JSONDictionary,
             let blockHash = valueJson["blockhash"] as? String {
            completion(blockHash)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  static func getLamportsPerSignature(completion: @escaping (Int?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.getRecentBlockhash) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJson = resultJson["value"] as? JSONDictionary,
             let feeJson = valueJson["feeCalculator"] as? JSONDictionary,
             let lamportsPerSignature = feeJson["lamportsPerSignature"] as? Int {
            completion(lamportsPerSignature)
            return
          }
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  func getTokenAccountsByOwner(ownerAddress: String, tokenAddress: String, completion: @escaping (String?, String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.getTokenAccountsByOwner(ownerAddress: ownerAddress, tokenAddress: tokenAddress)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let resultJson = json["result"] as? JSONDictionary,
             let valueJsons = resultJson["value"] as? [JSONDictionary] {
            for value in valueJsons {
              if let pubKey = value["pubkey"] as? String {
                let account = value["account"] as? JSONDictionary
                let data = account?["data"] as? JSONDictionary
                let parsed = data?["parsed"] as? JSONDictionary
                let info = parsed?["info"] as? JSONDictionary
                let tokenAmount = info?["tokenAmount"] as? JSONDictionary
                
                if let amount = tokenAmount?["amount"] as? String {
                  completion(amount, pubKey)
                  return
                }
                
                completion(nil, pubKey)
                return
              }
            }
          }
        }
        completion(nil, nil)
      case .failure(let error):
        completion(nil, nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
  func sendSignedTransaction(signedTransaction: String, completion: @escaping (String?) -> Void) {
    let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin()])
    provider.request(.sendTransaction(signedTransaction: signedTransaction)) { result in
      switch result {
      case .success(let data):
        if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          print(json)
          if let signatureResult = json["result"] as? String {
            completion(signatureResult)
            return
          }
          completion(nil)
        }
        completion(nil)
      case .failure(let error):
        completion(nil)
        print("[Solana error] \(error.localizedDescription)")
      }
    }
  }
  
    func getBalance(address: String, completion: @escaping (BigInt?) -> Void) {
      let provider = MoyaProvider<SolanaService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getBalance(address: address)) { result in
        switch result {
        case .success(let data):
          if let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
            if let resultJson = json["result"] as? JSONDictionary {
              if let value = resultJson["value"] as? Int {
                completion(BigInt(value))
                return
              }
            }
          }
          completion(nil)
        case .failure(let error):
          print("[Solana error] \(error.localizedDescription)")
          completion(nil)
        }
      }
    }
}

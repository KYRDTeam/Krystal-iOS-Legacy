//
//  UserService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 21/09/2022.
//

import Foundation
import Moya
import KrystalWallets
import AppState

class UserService {
    
    enum TransactionType: String {
        case swap
        case transfer
        case multisend
        case bridge
        case earn
        case claim
        case nft_transfer
        case undefine
    }
    
    enum TransactionState: String {
        case pending
        case success
        case failed
    }
    
    enum ChainType: String {
        case evm
        case solana
    }
  
  static let retryTimes = 3
  
  let provider = MoyaProvider<UserEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    static let shared = UserService()
  
  func connectEVM(remainRetryTime: Int = UserService.retryTimes, address: KAddress, completion: @escaping () -> ()) {
    let signer = SignerFactory().getSigner(address: address)
    let message = "\(address.addressString)_\(Int(Date().timeIntervalSince1970))"
    guard let signature = try? signer.signMessageHash(address: address, data: Data(message.utf8), addPrefix: true).hexEncoded else {
      completion()
      return
    }
    provider.requestWithFilter(.connectEvm(address: address.addressString, signature: signature)) { result in
      switch result {
      case .success(let response):
        do {
          let resp = try JSONDecoder().decode(ConnectEVMResponse.self, from: response.data)
          UserDefaults.standard.saveAuthToken(address: address.addressString, token: resp.token)
          completion()
        } catch {
          return
        }
      case .failure:
        if remainRetryTime > 0 {
          self.connectEVM(remainRetryTime: remainRetryTime - 1, address: address, completion: completion)
        } else {
          completion()
        }
      }
    }
  }
    
    func sumitTransaction(transaction: [String: Any], completion:((Bool) -> Void)? = nil) {
        provider.requestWithFilter(.sumitTransaction(transaction: transaction)) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }
  
    class func buildTransactionParam(type: TransactionType, chainType: ChainType, txHash: String, status: TransactionState, extra: [String: Any]) -> [String: Any] {
        let address = AppState.shared.currentAddress.addressString
        let chain = AppState.shared.currentChain.getChainId()
        
        return [
            "txType": type.rawValue,
            "walletAddress": address,
            "chainType": chainType.rawValue,
            "chainId": chain,
            "txHash": txHash,
            "status": status.rawValue,
            "extra": extra
        ]
    }
}

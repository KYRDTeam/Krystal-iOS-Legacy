//
//  UserService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 21/09/2022.
//

import Foundation
import Moya
import KrystalWallets

class UserService {
  
  static let retryTimes = 3
  
  let provider = MoyaProvider<UserEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
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
  
}

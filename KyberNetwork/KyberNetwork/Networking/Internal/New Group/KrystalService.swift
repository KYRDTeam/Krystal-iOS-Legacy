//
//  KrystalService.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation
import Moya

enum KrystalNetworkError: Error {
  case cannotDecode
}

class KrystalService {
  
  let provider = MoyaProvider<KrystalApi>(plugins: [NetworkLoggerPlugin()])
  
  func getSolanaTransactions(address: String, prevHash: String?, limit: Int, completion: @escaping (Result<[KrystalSolanaTransaction], Error>) -> ()) {
    provider.request(.transactions(address: address, prevHash: prevHash, limit: limit)) { result in
      switch result {
      case .success(let json):
        do {
          let listResponse = try! JSONDecoder().decode(KrystalSolanaTransactionListResponse.self, from: json.data)
          completion(.success(listResponse.transactions))
        } catch {
          completion(.failure(KrystalNetworkError.cannotDecode))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
}

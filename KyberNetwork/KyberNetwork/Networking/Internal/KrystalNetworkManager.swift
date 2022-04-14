//
//  KrystalNetworkManager.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 13/04/2022.
//

import Foundation
import Moya

struct RefPrice: Decodable {
  var refPrice: String?
  var sources: [String]
}

class KrystalNetworkManager {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func getRefPrice(srcContract: String, dstContract: String, completion: @escaping (Result<RefPrice, Error>) -> ()) {
    request(target: .getRefPrice(src: srcContract, dst: dstContract), completion: completion)
  }
  
}

private extension KrystalNetworkManager {
  func request<T: Decodable>(target: KrytalService, completion: @escaping (Result<T, Error>) -> ()) {
    provider.request(target) { result in
      switch result {
      case let .success(response):
        do {
          let results = try JSONDecoder().decode(T.self, from: response.data)
          completion(.success(results))
        } catch let error {
          completion(.failure(error))
        }
      case let .failure(error):
        completion(.failure(error))
      }
    }
  }
}

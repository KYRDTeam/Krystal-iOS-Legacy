//
//  MarketService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/07/2022.
//

import Foundation
import Moya

class MarketService {
  
  let provider = MoyaProvider<MarketEndpoint>(plugins: [NetworkLoggerPlugin()])
  
  func getTokenPrices(chainPath: String, quotes: [String], completion: @escaping ([TokenDTO]) -> ()) {
    provider.request(.overview(chainPath: chainPath, quotes: quotes)) { result in
      switch result {
      case .success(let response):
        print(String(data: response.data, encoding: .utf8) ?? "")
        do {
          let responseData = try JSONDecoder().decode(BaseResponse<[TokenDTO]>.self, from: response.data)
          completion(responseData.data ?? [])
        } catch {
          completion([])
        }
      default:
        completion([])
      }
    }
  }
  
}

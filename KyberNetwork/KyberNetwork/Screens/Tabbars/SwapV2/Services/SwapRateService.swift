//
//  SwapRateService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 04/08/2022.
//

import Foundation
import BigInt
import Moya

class SwapRateService {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func getAllRates(address: String, srcTokenContract: String, destTokenContract: String,
                   amount: BigInt, focusSrc: Bool, completion: @escaping ([Rate]) -> ()) {
    provider.requestWithFilter(.getAllRates(src: srcTokenContract.lowercased(), dst: destTokenContract.lowercased(),
                                            amount: amount.description, focusSrc: focusSrc, userAddress: address)) { result in
      switch result {
      case .success(let response):
        do {
          let data = try JSONDecoder().decode(RateResponse.self, from: response.data)
          let sortedRate = data.rates.sorted { rate1, rate2 in
            return BigInt.bigIntFromString(value: rate1.rate)  > BigInt.bigIntFromString(value: rate2.rate)
          }
          completion(sortedRate)
        } catch {
          completion([])
        }
      case .failure:
        completion([])
      }
    }
  }
  
}

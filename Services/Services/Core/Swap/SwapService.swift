//
//  RateService.swift
//  Services
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import Moya
import BigInt
import Utilities

public class SwapService {
    
    let provider = MoyaProvider<SwapEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    public init() {
        
    }
    
    public func getAllRates(chainPath: String, address: String, srcTokenContract: String, destTokenContract: String,
                            amount: BigInt, focusSrc: Bool, completion: @escaping ([Rate]) -> ()) {
        provider.request(.getAllRates(chainPath: chainPath, src: srcTokenContract.lowercased(), dst: destTokenContract.lowercased(),
                                      amount: amount.description, focusSrc: focusSrc, userAddress: address)) { result in
            switch result {
            case .success(let response):
                do {
                    let data = try JSONDecoder().decode(RateResponse.self, from: response.data)
                    completion(data.rates)
                } catch {
                    completion([])
                }
            case .failure:
                completion([])
            }
        }
    }
    
//    func getExpectedRate(chainPath: String, sourceToken: String, destToken: String, srcAmount: BigInt, hint: String, completion: @escaping (Result<Rate, SwapServiceError>) -> ()) {
//        let amt = srcAmount.description
//        provider.request(.getExpectedRate(chainPath: chainPath, src: sourceToken, dst: destToken, srcAmount: amt, hint: hint, isCaching: true)) { result in
//            switch result {
//            case .success(let resp):
//                completion(.success(<#T##Rate#>))
//            case .failure(let error):
//                ()
//            }
//            if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let rate = json["rate"] as? String, let rateBigInt = BigInt(rate) {
//                completion(.success(<#T##Rate#>))
//            } else {
//                self.rootViewController.coordinatorDidUpdateExpectedRate(from: from, to: to, amount: srcAmount, rate: BigInt(0))
//            }
//        }
//    }
    
}

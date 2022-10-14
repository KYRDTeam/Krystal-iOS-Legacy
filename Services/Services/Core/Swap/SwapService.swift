//
//  RateService.swift
//  Services
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation
import Moya
import BigInt

public class SwapService {
    
    let provider = MoyaProvider<SwapEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    public init() {
        
    }
    
    public func getAllRates(address: String, srcTokenContract: String, destTokenContract: String,
                     amount: BigInt, focusSrc: Bool, completion: @escaping ([Rate]) -> ()) {
        provider.request(.getAllRates(src: srcTokenContract.lowercased(), dst: destTokenContract.lowercased(),
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
    
//    func getExpectedRate(sourceToken: String, destToken: String, srcAmount: BigInt, hint: String, completion: @escaping Result<Rate, SwapServiceError>) {
//        let amt = srcAmount.description
//        provider.request(.getExpectedRate(src: sourceToken, dst: destToken, srcAmount: amt, hint: hint, isCaching: true)) { result in
//            switch result {
//            case .success(let resp):
//                ()
//            case .failure(let error):
//                ()
//            }
//            if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let rate = json["rate"] as? String, let rateBigInt = BigInt(rate) {
//                self.rootViewController.coordinatorDidUpdateExpectedRate(from: from, to: to, amount: srcAmount, rate: rateBigInt)
//            } else {
//                self.rootViewController.coordinatorDidUpdateExpectedRate(from: from, to: to, amount: srcAmount, rate: BigInt(0))
//            }
//        }
//    }
    
}

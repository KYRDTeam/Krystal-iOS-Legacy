//
//  SwapRateService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 04/08/2022.
//

import Foundation
import BigInt
import Moya
import KrystalWallets
import Result

class SwapRepository {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func getAllRates(address: String, srcTokenContract: String, destTokenContract: String,
                   amount: BigInt, focusSrc: Bool, completion: @escaping ([Rate]) -> ()) {
    provider.requestWithFilter(.getAllRates(src: srcTokenContract.lowercased(), dst: destTokenContract.lowercased(),
                                            amount: amount.description, focusSrc: focusSrc, userAddress: address)) { result in
      switch result {
      case .success(let response):
        do {
          let data = try JSONDecoder().decode(RateResponse.self, from: response.data)
          let sortedRates = data.rates.sorted { lhs, rhs in
            return BigInt.bigIntFromString(value: lhs.rate) > BigInt.bigIntFromString(value: rhs.rate)
          }
          completion(sortedRates)
        } catch {
          completion([])
        }
      case .failure:
        completion([])
      }
    }
  }
  
  func getBalance(tokenAddress: String, address: String, completion: @escaping (BigInt?, String) -> ()) {
    if tokenAddress == KNGeneralProvider.shared.quoteTokenObject.address { // is native token
      KNGeneralProvider.shared.getETHBalanace(for: address) { result in
        switch result {
        case .success(let balance):
          completion(balance.value, tokenAddress)
        case .failure:
          completion(nil, tokenAddress)
        }
      }
    } else {
      KNGeneralProvider.shared.getTokenBalance(for: address, contract: tokenAddress) { result in
        switch result {
        case .success(let amount):
          completion(amount, tokenAddress)
        case .failure:
          completion(nil, tokenAddress)
        }
      }
    }
  }
  
  func getRefPrice(sourceToken: String, destToken: String, completion: @escaping (String?) -> ()) {
    provider.requestWithFilter(.getRefPrice(src: sourceToken.lowercased(), dst: destToken.lowercased())) { [weak self] result in
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let change = json["refPrice"] as? String {
        completion(change)
      } else {
        completion(nil)
      }
    }
  }
  
  func getAllowance(tokenAddress: String, address: String, completion: @escaping (BigInt, String) -> ()) {
    let networkAddress = KNGeneralProvider.shared.proxyAddress
    KNGeneralProvider.shared.getAllowance(for: address, networkAddress: networkAddress, tokenAddress: tokenAddress) { result in
      switch result {
      case .success(let allowance):
        completion(allowance, tokenAddress)
      case .failure:
        completion(0, tokenAddress)
      }
    }
  }
  
  func approve(address: KAddress, tokenAddress: String, value: BigInt, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> ()) {
    let networkAddress = KNGeneralProvider.shared.networkAddress
    let currentChain = KNGeneralProvider.shared.currentChain
    let nonce = NonceCache.shared.getCachingNonce(address: address.addressString, chain: currentChain)
    KNGeneralProvider.shared.approve(address: address, tokenAddress: tokenAddress, value: value, currentNonce: nonce, networkAddress: networkAddress, gasPrice: gasPrice, gasLimit: gasLimit) { result in
      switch result {
      case .success(let nonce):
        NonceCache.shared.updateNonce(address: address.addressString, chain: currentChain, nonce: nonce)
        completion(.success(true))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getCommonBaseTokens(completion: @escaping ([Token]) -> ()) {
    provider.request(.getCommonBaseToken) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let tokenJsons = json["tokens"] as? [JSONDictionary] {
          let tokens = tokenJsons.map { Token(dictionary: $0) }
          completion(tokens)
        } else {
          completion([])
        }
      case .failure:
        completion([])
      }
    }
  }
  
}

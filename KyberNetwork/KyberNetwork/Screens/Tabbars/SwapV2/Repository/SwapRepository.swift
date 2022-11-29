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
import AppState
import Services

class SwapRepository {
    
  var session: KNSession {
    return AppDelegate.session
  }
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func getAllRates(address: String, srcTokenContract: String, destTokenContract: String,
                   amount: BigInt, focusSrc: Bool, completion: @escaping ([Rate]) -> ()) {
    provider.requestWithFilter(.getAllRates(src: srcTokenContract.lowercased(), dst: destTokenContract.lowercased(),
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
  
  func getBalance(tokenAddress: String, address: String, completion: @escaping (BigInt?, String) -> ()) {
    if tokenAddress.lowercased() == KNGeneralProvider.shared.quoteTokenObject.address.lowercased() { // is native token
      KNGeneralProvider.shared.getETHBalanace(for: address) { result in
        switch result {
        case .success(let balance):
          completion(balance.value, tokenAddress)
        case .failure:
          completion(nil, tokenAddress)
        }
      }
    } else {
      KNGeneralProvider.shared.getTokenBalance(for: address, contract: tokenAddress.lowercased()) { result in
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
  
  func approve(address: KAddress, tokenAddress: String, currentAllowance: BigInt, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> ()) {
    let networkAddress = KNGeneralProvider.shared.networkAddress
    let currentChain = KNGeneralProvider.shared.currentChain
    let currentNonce = NonceCache.shared.getCachingNonce(address: address.addressString, chain: currentChain)
    
    let approveMaxFunction: (Int, @escaping (Result<Bool, AnyError>) -> ()) -> () = { nonce, completion in
      KNGeneralProvider.shared.approve(address: address, tokenAddress: tokenAddress, value: Constants.maxValueBigInt, currentNonce: nonce, networkAddress: networkAddress, gasPrice: gasPrice, gasLimit: gasLimit) { result in
        switch result {
        case .success(let newNonce):
          NonceCache.shared.updateNonce(address: address.addressString, chain: currentChain, nonce: newNonce)
          completion(.success(true))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
    
    if currentAllowance.isZero {
      approveMaxFunction(currentNonce, completion)
    } else {
      // Reset to 0
      KNGeneralProvider.shared.approve(address: address, tokenAddress: tokenAddress, value: .zero, currentNonce: currentNonce, networkAddress: networkAddress, gasPrice: gasPrice, gasLimit: gasLimit) { result in
        switch result {
        case .success(let nonce):
          NonceCache.shared.updateNonce(address: address.addressString, chain: currentChain, nonce: nonce)
          approveMaxFunction(nonce, completion)
        case .failure(let error):
          completion(.failure(error))
        }
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
  
  func getTokenDetail(tokenAddress: String, completion: @escaping (TokenDetailInfo?) -> ()) {
    let chainPath = KNGeneralProvider.shared.chainPath
    provider.request(.getTokenDetail(chainPath: chainPath, address: tokenAddress)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TokenDetailResponse.self, from: response.data)
          completion(data.result)
        } catch {
          completion(nil)
        }
      case .failure:
        completion(nil)
      }
    }
  }
  
    
    func buildTx(tx: RawSwapTransaction, completion: @escaping (TransactionResponse) -> Void) {
      provider.requestWithFilter(.buildSwapTx(address: tx.userAddress, src: tx.src, dst: tx.dest, srcAmount: tx.srcQty, minDstAmount: tx.minDesQty, gasPrice: tx.gasPrice, nonce: tx.nonce, hint: tx.hint, useGasToken: tx.useGasToken)) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(TransactionResponse.self, from: resp.data)
            completion(data)
          } catch {
            self.showError(errorMsg: "Parse Tx Data Error")
          }
        case .failure(let error):
          self.showError(errorMsg: error.localizedDescription)
        }
      }
    }
    
    func getL1FeeForTxIfHave(object: TxObject, completion: @escaping (BigInt, TxObject) -> Void) {
        if AppState.shared.currentChain == .optimism {
            let service = EthereumNodeService(chain: AppState.shared.currentChain)
            service.getOPL1FeeEncodeData(for: object.data) { result in
                switch result {
                case .success(let encodeString):
                    service.getOptimismL1Fee(for: encodeString) { feeResult in
                        switch feeResult {
                        case .success(let fee):
                            completion(fee, object)
                        case .failure(let error):
                            self.showError(errorMsg: error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    self.showError(errorMsg: error.localizedDescription)
                }
            }
        } else {
            completion(BigInt(0), object)
        }
    }
    
    func getLatestNonce(completion: @escaping (Int) -> Void) {
      guard let provider = self.session.externalProvider else {
        return
      }
      provider.getTransactionCount { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let res):
          completion(res)
        case .failure(let error):
          self.showError(errorMsg: error.localizedDescription)
        }
      }
    }
    
    func showError(errorMsg: String) {
      UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.showErrorTopBannerMessage(message: errorMsg)
    }
}

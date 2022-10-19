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
import Services
import BaseWallet
import AppState

class SwapRepository {
    
    func getBalance(tokenAddress: String, address: String, completion: @escaping (BigInt?, String) -> ()) {
        //    if tokenAddress == KNGeneralProvider.shared.quoteTokenObject.address { // is native token
        //      KNGeneralProvider.shared.getETHBalanace(for: address) { result in
        //        switch result {
        //        case .success(let balance):
        //          completion(balance.value, tokenAddress)
        //        case .failure:
        //          completion(nil, tokenAddress)
        //        }
        //      }
        //    } else {
        //      KNGeneralProvider.shared.getTokenBalance(for: address, contract: tokenAddress) { result in
        //        switch result {
        //        case .success(let amount):
        //          completion(amount, tokenAddress)
        //        case .failure:
        //          completion(nil, tokenAddress)
        //        }
        //      }
        //    }
    }
    //
    //  func getRefPrice(sourceToken: String, destToken: String, completion: @escaping (String?) -> ()) {
    //    provider.requestWithFilter(.getRefPrice(src: sourceToken.lowercased(), dst: destToken.lowercased())) { [weak self] result in
    //      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let change = json["refPrice"] as? String {
    //        completion(change)
    //      } else {
    //        completion(nil)
    //      }
    //    }
    //  }
    //
    func getAllowance(tokenAddress: String, address: String, completion: @escaping (BigInt, String) -> ()) {
        //    let networkAddress = KNGeneralProvider.shared.proxyAddress
        //    KNGeneralProvider.shared.getAllowance(for: address, networkAddress: networkAddress, tokenAddress: tokenAddress) { result in
        //      switch result {
        //      case .success(let allowance):
        //        completion(allowance, tokenAddress)
        //      case .failure:
        //        completion(0, tokenAddress)
        //      }
        //    }
    }
    //
    func approve(address: KAddress, tokenAddress: String, currentAllowance: BigInt, gasPrice: BigInt, gasLimit: BigInt, completion: @escaping (Result<Bool, AnyError>) -> ()) {
//        let networkAddress = KNGeneralProvider.shared.networkAddress
//        let currentChain = AppState.shared.currentChain
//        let currentNonce = Dependencies.nonceStorage.currentNonce(chain: currentChain, address: address.addressString)
//        
//        let approveMaxFunction: (Int, @escaping (Result<Bool, AnyError>) -> ()) -> () = { nonce, completion in
//            KNGeneralProvider.shared.approve(address: address, tokenAddress: tokenAddress, value: Constants.maxValueBigInt, currentNonce: nonce, networkAddress: networkAddress, gasPrice: gasPrice, gasLimit: gasLimit) { result in
//                switch result {
//                case .success(let newNonce):
//                    NonceCache.shared.updateNonce(address: address.addressString, chain: currentChain, nonce: newNonce)
//                    completion(.success(true))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
//        
//        if currentAllowance.isZero {
//            approveMaxFunction(currentNonce, completion)
//        } else {
//            // Reset to 0
//            KNGeneralProvider.shared.approve(address: address, tokenAddress: tokenAddress, value: .zero, currentNonce: currentNonce, networkAddress: networkAddress, gasPrice: gasPrice, gasLimit: gasLimit) { result in
//                switch result {
//                case .success(let nonce):
//                    NonceCache.shared.updateNonce(address: address.addressString, chain: currentChain, nonce: nonce)
//                    approveMaxFunction(nonce, completion)
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
        
    }
    
}

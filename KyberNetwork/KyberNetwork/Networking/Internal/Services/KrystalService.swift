//
//  KrystalService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/08/2022.
//

import Foundation
import KrystalWallets
import Moya
import Result

class KrystalService {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin()])
  
  func sendRefCode(address: KAddress, _ code: String, completion: @escaping (_ isSuccess: Bool, _ message: String) -> ()) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let signer = SignerFactory().getSigner(address: address)
    do {
      let signedData = try signer.signMessageHash(address: address, data: sendData, addPrefix: false)
      provider.requestWithFilter(.registerReferrer(address: address.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            completion(true, "Success register referral code")
          } else if let error = json["error"] as? String {
            completion(false, error)
          } else {
            completion(false, "Fail to register referral code")
          }
        }
      }
    } catch {
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
  
  func getStakingPortfolio(address: String, completion: @escaping (Result<([EarningBalance], [PendingUnstake]), AnyError>) -> Void) {
    let group = DispatchGroup()
    var eb: [EarningBalance]?
    var pu: [PendingUnstake]?
    
    var anyError: AnyError?
    
    group.enter()
    
    provider.requestWithFilter(.getEarningBalances(address: address)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(EarningBalancesResponse.self, from: response.data)
          eb = decoded.earningBalances
        } catch let error {
          anyError = AnyError(error)
        }
      case .failure(let error):
        anyError = AnyError(error)
      }
      group.leave()
    }
    
    group.enter()
    provider.requestWithFilter(.getPendingUnstakes(address: address)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(PendingUnstakesResponse.self, from: response.data)
          pu = decoded.pendingUnstakes
        } catch let error {
          anyError = AnyError(error)
        }
      case .failure(let error):
        anyError = AnyError(error)
      }
      group.leave()
    }
    
    group.notify(queue: .main) {
      let uw_eb = eb ?? []
      let uw_pu = pu ?? []
      completion(.success((uw_eb, uw_pu)))
    }
  }
  
  func getStakingOptionDetail(platform: String, earningType: String, chainID: String, tokenAddress: String, completion: @escaping (Result<[EarningToken], AnyError>) -> Void) {
    provider.requestWithFilter(.getEarningOptionDetail(platform: platform, earningType: earningType, chainID: chainID, tokenAddress: tokenAddress)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(OptionDetailResponse.self, from: response.data)
          completion(.success(decoded.earningTokens))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func buildStakeTx(param: JSONDictionary, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
    provider.requestWithFilter(.buildStakeTx(params: param)) { result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(TransactionResponse.self, from: resp.data)
          completion(.success(data.txObject))
          
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
}

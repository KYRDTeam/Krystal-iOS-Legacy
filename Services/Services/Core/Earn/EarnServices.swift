//
//  EarnServices.swift
//  Services
//
//  Created by Com1 on 27/10/2022.
//

import Foundation
import Moya
import Utilities
import Result

public class EarnServices: BaseService {
  let provider = MoyaProvider<EarnEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
  var currentProcess: Cancellable?

  public func getEarnListData(chainId: String?, completion: @escaping ([EarnPoolModel]) -> ()) {
    if let currentProcess = currentProcess {
      currentProcess.cancel()
    }
    self.currentProcess = provider.requestWithFilters(.listOption(chainId: chainId)) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let jsonResults = json["result"] as? [JSONDictionary] {
          
          var earnPools: [EarnPoolModel] = []
          jsonResults.forEach { jsonResult in
            earnPools.append(EarnPoolModel(json: jsonResult))
          }
          completion(earnPools)
        } else {
          completion([])
        }
      case .failure:
        completion([])
      }
    } as? Cancellable
  }
  
  public func getStakingPortfolio(address: String, completion: @escaping (Result<([EarningBalance], [PendingUnstake]), AnyError>) -> Void) {
    let group = DispatchGroup()
    var eb: [EarningBalance]?
    var pu: [PendingUnstake]?
    
    var anyError: AnyError?
    
    group.enter()
    
    provider.requestWithFilters(.getEarningBalances(address: address)) { result in
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
    provider.requestWithFilters(.getPendingUnstakes(address: address)) { result in
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
  
  public func getStakingOptionDetail(platform: String, earningType: String, chainID: String, tokenAddress: String, completion: @escaping (Result<OptionDetailResponse, AnyError>) -> Void) {
    
    provider.requestWithFilters(.getEarningOptionDetail(platform: platform, earningType: earningType, chainID: chainID, tokenAddress: tokenAddress)) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let decoded = try decoder.decode(OptionDetailResponse.self, from: response.data)
          completion(.success(decoded))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  public func buildStakeTx(param: JSONDictionary, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
    provider.requestWithFilters(.buildStakeTx(params: param)) { result in
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
    
    public func buildClaimTx(param: JSONDictionary, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
        provider.requestWithFilters(.buildClaimTx(params: param)) { result in
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

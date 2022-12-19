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
            
          earnPools = earnPools.sorted(by: { return $0.tvl > $1.tvl })
          completion(earnPools)
        } else {
          completion([])
        }
      case .failure:
        completion([])
      }
    } as? Cancellable
  }
  
  public func getStakingPortfolio(address: String, chainId: String?, completion: @escaping (Result<([EarningBalance], [PendingUnstake]), AnyError>) -> Void) {
    let group = DispatchGroup()
    var eb: [EarningBalance]?
    var pu: [PendingUnstake]?
    
    var anyError: AnyError?
    
    group.enter()
    
    provider.requestWithFilters(.getEarningBalances(address: address, chainId: chainId)) { result in
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
      var unwrapEarningBalances = eb ?? []
      var unwrapPendingUnstake = pu ?? []
      unwrapEarningBalances = unwrapEarningBalances.sorted(by: { return $0.underlyingUsd > $1.underlyingUsd })
      unwrapPendingUnstake = unwrapPendingUnstake.sorted(by: { return $0.priceUsd > $1.priceUsd })
      completion(.success((unwrapEarningBalances, unwrapPendingUnstake)))
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
    
    public func buildUnstakeTx(param: JSONDictionary, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
        provider.requestWithFilters(.buildUnstakeTx(params: param)) { result in
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
    
    public func getPendingReward(address: String, completion: @escaping (Result<PendingRewardResponse, AnyError>) -> Void) {
        provider.requestWithFilters(.getPendingReward(address: address)) { result in
            switch result {
            case .success(let resp):
              let decoder = JSONDecoder()
              do {
                let data = try decoder.decode(PendingRewardResponse.self, from: resp.data)
                completion(.success(data))
                
              } catch let error {
                completion(.failure(AnyError(error)))
              }
            case .failure(let error):
              completion(.failure(AnyError(error)))
            }
        }
    }
    
    public func buildClaimReward(chainId: Int, from: String, platform: String, completion: @escaping (Result<TxObject, AnyError>) -> Void) {
        provider.requestWithFilters(.buildClaimReward(chainId: chainId, from: from, platform: platform)) { result in
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

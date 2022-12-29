//
//  TokenService.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Moya
import BaseWallet
import Utilities

public class TokenService: BaseService {
  
  let provider = MoyaProvider<TokenEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
  var searchTokensProcess: Cancellable?
    var advancedSearchCancellable: Cancellable?
  
  public func getTokenDetail(address: String, chainPath: String, completion: @escaping (TokenDetailInfo?) -> ()) {
    provider.request(.getTokenDetail(chainPath: chainPath, address: address)) { result in
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
  
  public func getCommonBaseTokens(chainPath: String, completion: @escaping ([Token]) -> ()) {
    provider.request(.getCommonBaseToken(chainPath: chainPath)) { result in
      switch result {
      case .success(let response):
        if let json = try? response.mapJSON() as? [String: Any] ?? [:], let tokenJsons = json["tokens"] as? [[String: Any]] {
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
  
  public func getPoolList(tokenAddress: String, chainID: Int, completion: @escaping ([TokenPoolDetail]) -> ()) {
    provider.request(.getPoolList(tokenAddress: tokenAddress, chainID: chainID, limit: 50)) { result in
      switch result {
      case .failure:
        completion([])
      case .success(let resp):
        var allPools: [TokenPoolDetail] = []
        if let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let jsonData = json["data"] as? [JSONDictionary] {
          jsonData.forEach { poolJson in
            let tokenPoolDetail = TokenPoolDetail(json: poolJson)
            if !tokenPoolDetail.token0.symbol.isEmpty && !tokenPoolDetail.token1.symbol.isEmpty {
              allPools.append(tokenPoolDetail)
            }
          }
        }
        completion(allPools)
      }
    }
  }
  
  public func getChartData(chainPath: String, tokenAddress: String, quote: String, from: Int, to: Int, completion: @escaping ([[Double]]) -> ()) {
    provider.request(.getChartData(chainPath: chainPath, address: tokenAddress, quote: quote, from: from, to: to)) { result in
      switch result {
      case .failure:
        completion([])
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ChartDataResponse.self, from: resp.data)
          completion(data.prices)
        } catch {
          completion([])
        }
      }
    }
  }
    
    public func getSearchTokens(chainPath: String, address: String, query: String, orderBy: String, completion: @escaping ([SearchToken]?) -> ()) {
        if let searchTokensProcess = self.searchTokensProcess {
          searchTokensProcess.cancel()
        }
        self.searchTokensProcess = provider.request(.getSearchToken(chainPath: chainPath, address: address, query: query, orderBy: orderBy)) { result in
          switch result {
          case .success(let response):
            if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let balancesJsons = json["balances"] as? [JSONDictionary] {
              var tokens: [SearchToken] = []
              balancesJsons.forEach { balanceJsons in
                tokens.append(SearchToken(json: balanceJsons))
              }
              completion(tokens)
            } else {
              completion(nil)
            }
          case .failure:
            completion(nil)
          }
        }
    }
    
    public func advancedSearch(query: String, limit: Int = 50, completion: @escaping ([AdvancedSearchToken]) -> ()) {
        advancedSearchCancellable?.cancel()
        advancedSearchCancellable = provider.request(.advancedSearch(query: query, limit: limit)) { result in
            switch result {
            case .success(let response):
                do {
                    let resp = try JSONDecoder().decode(AdvancedSearchResponse.self, from: response.data)
                    completion(resp.data?.tokens ?? [])
                } catch {
                    completion([])
                }
            case .failure:
                completion([])
            }
        }
    }
    
}

//
//  TokenService.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 02/02/2023.
//

import Foundation
import Moya

class TokenService {
    
    let provider = MoyaProvider<TokenEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    public func getTokenList(chainPath: String, completion: @escaping ([TokenModel]) -> ()) {
        provider.request(.getTokenList(chainPath: chainPath)) { result in
            switch result {
            case .success(let response):
                do {
                    let tokenListRes = try JSONDecoder().decode(TokenListResponse.self, from: response.data)
                    completion(tokenListRes.tokens ?? [])
                } catch {
                    completion([])
                }
            case .failure:
                completion([])
            }
        }
    }
    
    public func getBalance(chainIDs: [Int], addresses: [String], completion: @escaping ([ChainBalanceModel]) -> ()) {
        provider.request(.getBalance(chainIDs: chainIDs, addresses: addresses)) { result in
            switch result {
            case .success(let response):
                do {
                    let balanceResponse = try JSONDecoder().decode(BalanceResponse.self, from: response.data)
                    completion(balanceResponse.data ?? [])
                } catch {
                    completion([])
                }
            case .failure:
                completion([])
            }
        }
    }
    
}

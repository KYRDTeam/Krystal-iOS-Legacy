//
//  TokenService.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Moya
import BaseWallet

public class TokenService: BaseService {
    
    let provider = MoyaProvider<TokenEndpoint>(plugins: [])
    
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
    
    public func getCommonBaseTokens(completion: @escaping ([Token]) -> ()) {
        provider.request(.getCommonBaseToken) { result in
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
    
}

//
//  HistoryService.swift
//  Services
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Moya

public class HistoryService: BaseService {
    
    let provider = MoyaProvider<HistoryEndpoint>(plugins: [NetworkLoggerPlugin()])
    
    public func getTxHistory(walletAddress: String, tokenAddress: String?, chainIds: [Int], limit: Int, endTime: Int?, completion: @escaping ([TxRecord]) -> ()) {
        provider.request(.getHistory(walletAddress: walletAddress, tokenAddress: tokenAddress, chainIds: chainIds, limit: limit, endTime: endTime)) { result in
            switch result {
            case .success(let response):
                do {
                    let resp = try JSONDecoder().decode(HistoryResponse.self, from: response.data)
                    completion(resp.data ?? [])
                } catch {
                    completion([])
                }
            case .failure:
                completion([])
            }
        }
    }
    
    public func getTxStats(address: String, chainIds: [Int], completion: @escaping (TxStatsData?) -> ()) {
        provider.request(.txStats(address: address, chainIds: chainIds)) { result in
            switch result {
            case .success(let response):
                do {
                    let resp = try JSONDecoder().decode(TxStatsResponse.self, from: response.data)
                    completion(resp.data)
                } catch {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }
    
}

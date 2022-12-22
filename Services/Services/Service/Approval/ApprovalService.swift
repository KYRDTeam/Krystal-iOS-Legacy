//
//  ApprovalService.swift
//  Services
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation
import Moya

public class ApprovalService: BaseService {
    
    let provider = MoyaProvider<ApprovalEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    public func getListApproval(address: String, chainIds: [Int], completion: @escaping (ApprovalsResponse?) -> ()) -> Cancellable? {
        return provider.request(.list(address: address, chainIds: chainIds)) { result in
            switch result {
            case .success(let response):
                guard let approvalsResponse = try? JSONDecoder().decode(ApprovalsResponse.self, from: response.data) else {
                    completion(nil)
                    return
                }
                completion(approvalsResponse)
            case .failure:
                completion(nil)
            }
        }
    }
    
}

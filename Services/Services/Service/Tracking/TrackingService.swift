//
//  TrackingService.swift
//  Services
//
//  Created by Tung Nguyen on 03/01/2023.
//

import Foundation
import Moya

public class TrackingService: BaseService {
    
    let provider = MoyaProvider<TrackingEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    public func sendRate(star: Int, detail: String, txHash: String) {
        provider.request(.sendRate(star: star, detail: detail, txHash: txHash)) { _ in }
    }
    
}

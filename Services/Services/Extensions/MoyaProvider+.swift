//
//  MoyaProvider+.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation
import Moya

public typealias WrappedCompletion = (_ result: Result<Moya.Response, NetworkError>) -> Void

public extension MoyaProvider {
    func requestWithFilters(successCodes: ClosedRange<Int> = 200...299, _ target: Target, completion: @escaping WrappedCompletion) {
        self.request(target) { result in
            switch result {
            case .success(let response):
                guard successCodes.contains(response.statusCode) else {
                    let decoder = JSONDecoder()
                    do {
                        let data = try decoder.decode(ErrorResponse.self, from: response.data)
                        let err = NetworkError.backendError(reponse: data)
                        completion(.failure(err))
                        ServiceConfig.errorTracker.track(error: err.toNSError())
                        
                    } catch let error {
                        let err = NetworkError.unknow(description: "Decode Error: \(error.localizedDescription)")
                        completion(.failure(err))
                        ServiceConfig.errorTracker.track(error: err.toNSError())
                    }
                    return
                }
                completion(.success(response))
            case .failure(let error):
                let err = NetworkError.unknow(description: error.localizedDescription)
                completion(.failure(err))
                ServiceConfig.errorTracker.track(error: err.toNSError())
            }
        }
    }
    
}

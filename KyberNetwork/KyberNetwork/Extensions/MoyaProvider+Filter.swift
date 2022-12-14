//
//  MoyaProvider+Filter.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/07/2022.
//

import Foundation
import Moya
import Sentry
import Mixpanel
import Dependencies

typealias WrappedCompletion = (_ result: Result<Moya.Response, NetworkError>) -> Void

extension MoyaProvider {
    func requestWithFilter(successCodes: ClosedRange<Int> = 200...299, _ target: Target, completion: @escaping WrappedCompletion) {
        self.request(target) { result in
            switch result {
            case .success(let response):
                guard successCodes.contains(response.statusCode) else {
                    let decoder = JSONDecoder()
                    do {
                        let data = try decoder.decode(ErrorResponse.self, from: response.data)
                        let err = NetworkError.backendError(reponse: data, code: response.statusCode)
                        completion(.failure(err))
                        SentrySDK.capture(error: err.toNSError())
                        
                    } catch let error {
                        let err = NetworkError.unknow(description: "Decode Error: \(error.localizedDescription)")
                        completion(.failure(err))
                        SentrySDK.capture(error: err.toNSError())
                    }
                    return
                }
                completion(.success(response))
            case .failure(let error):
                let err = NetworkError.unknow(description: error.localizedDescription)
                completion(.failure(err))
                SentrySDK.capture(error: err.toNSError())
            }
        }
    }
    
}

//
//  MoyaProvider+Filter.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/07/2022.
//

import Foundation
import Moya

typealias WrappedCompletion = (_ result: Result<Moya.Response, NetworkError>) -> Void

extension MoyaProvider {
  func requestWithFilter(_ target: Target, completion: @escaping WrappedCompletion) {
    self.request(target) { result in
      switch result {
      case .success(let response):
        guard response.statusCode == 200 else {
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(ErrorResponse.self, from: response.data)
            completion(.failure(NetworkError.backendError(reponse: data)))
          } catch let error {
            completion(.failure(.unknow(description: "Decode Error: \(error.localizedDescription)")))
          }
          return
        }
        completion(.success(response))
      case .failure(let error):
        completion(.failure(.unknow(description: error.localizedDescription)))
      }
    }
  }
  
}

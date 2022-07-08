//
//  ErrorResponse.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/07/2022.
//

import Foundation

enum NetworkError: Error {
  case backendError(reponse: ErrorResponse)
  case unknow(description: String)
  
  func localizedDescription() -> String {
    switch self {
    case .backendError(let reponse):
      return reponse.error
    case .unknow(let description):
      return description
    }
  }
}

// MARK: - ErrorResponse
struct ErrorResponse: Codable {
    let timestamp: Int
    let error: String
}

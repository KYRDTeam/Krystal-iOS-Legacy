//
//  NetworkError.swift
//  Services
//
//  Created by Tung Nguyen on 12/10/2022.
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
    
    func toNSError() -> NSError {
        return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription])
    }
}

struct ErrorResponse: Codable {
    let timestamp: Int
    let error: String
}

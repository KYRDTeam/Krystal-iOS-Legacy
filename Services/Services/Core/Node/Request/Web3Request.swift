//
//  Web3Request.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

protocol Web3Request {
    associatedtype Response: Decodable
    var type: Web3RequestType { get }
}

enum Web3RequestType {
    case function(command: String)
    case variable(command: String)
    case script(command: String)
}

//
//  Web3Request.swift
//  ChainModule
//
//  Created by Tung Nguyen on 02/02/2023.
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

//
//  Converter.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

protocol Converter {
    associatedtype Input
    associatedtype Output
    
    static func convert(input: Input) -> Output
}

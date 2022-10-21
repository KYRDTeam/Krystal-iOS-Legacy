//
//  CastError.swift
//  Services
//
//  Created by Tung Nguyen on 14/10/2022.
//

import Foundation

struct CastError<ExpectedType>: Error {
    let actualValue: Any
    let expectedType: ExpectedType.Type
}

//
//  Logger.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation

func measureTime(tag: String, functionName: String, block: () -> ()) {
    let date = Date()
    block()
    print(tag, functionName, Date().timeIntervalSince(date))
}

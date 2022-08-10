//
//  SwapObject.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation

struct SwapObject {
  var sourceToken: Token
  var destToken: Token
  var sourceAmount: BigInt
  var rate: Rate
}

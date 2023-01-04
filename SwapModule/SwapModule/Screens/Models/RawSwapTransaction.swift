//
//  RawSwapTransaction.swift
//  SwapModule
//
//  Created by Tung Nguyen on 05/12/2022.
//

import Foundation

struct RawSwapTransaction {
  let userAddress: String
  let src: String
  let dest: String
  let srcQty: String
  let minDesQty: String
  let gasPrice: String
  let nonce: Int
  let hint: String
  let useGasToken: Bool
}

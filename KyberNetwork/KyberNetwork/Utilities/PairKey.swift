//
//  PairKey.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 04/04/2022.
//

import Foundation

struct PairKey<T: Hashable, U: Hashable>: Hashable {
  let key1: T
  let key2: U
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(key1)
    hasher.combine(key2)
  }
  
}

func ==<T: Hashable, U: Hashable>(lhs: PairKey<T,U>, rhs: PairKey<T,U>) -> Bool {
  return lhs.key1 == rhs.key1 && lhs.key2 == rhs.key2
}

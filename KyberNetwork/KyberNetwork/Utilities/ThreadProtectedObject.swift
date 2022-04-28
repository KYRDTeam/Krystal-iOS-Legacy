//
//  MultithreadProtectedObject.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 03/04/2022.
//

import Foundation
import Accessibility

class ThreadProtectedObject<Value> {
  var storageValue: Value
  let queue: DispatchQueue
  
  init(storageValue: Value) {
    self.queue = DispatchQueue(label: String(describing: Value.self) + "-" + UUID().uuidString)
    self.storageValue = storageValue
  }
  
  var value: Value {
    get {
      queue.sync { storageValue }
    }
    set {
      queue.sync { storageValue = newValue }
    }
  }
}

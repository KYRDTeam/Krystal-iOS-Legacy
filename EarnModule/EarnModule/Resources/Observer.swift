//
//  Observable.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 26/04/2022.
//

import Foundation

final class Observable<Value> {
  
  struct Observer<Value> {
    weak var observer: AnyObject?
    let block: (Value) -> Void
  }
  
  private var observers = [Observer<Value>]()
  
  var value: Value {
    didSet { notifyObservers() }
  }
  
  init(_ value: Value) {
    self.value = value
  }
  
  func observe(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
    observers.append(Observer(observer: observer, block: observerBlock))
  }
  
  func observeAndFire(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
    observers.append(Observer(observer: observer, block: observerBlock))
    observerBlock(self.value)
  }
  
  func remove(observer: AnyObject) {
    observers = observers.filter { $0.observer !== observer }
  }
  
  private func notifyObservers() {
    for observer in observers {
      DispatchQueue.main.async { observer.block(self.value) }
    }
  }
}

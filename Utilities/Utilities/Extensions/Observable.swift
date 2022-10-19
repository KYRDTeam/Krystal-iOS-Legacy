//
//  Observable.swift
//  Utilities
//
//  Created by Tung Nguyen on 12/10/2022.
//

import Foundation

public final class Observable<Value> {
    
    public struct Observer<Value> {
        weak var observer: AnyObject?
        let block: (Value) -> Void
        
        public init(observer: AnyObject?, block: @escaping (Value) -> Void) {
            self.observer = observer
            self.block = block
        }
    }
    
    private var observers = [Observer<Value>]()
    
    public var value: Value {
        didSet { notifyObservers() }
    }
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public func observe(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
        observers.append(Observer(observer: observer, block: observerBlock))
    }
    
    public func observeAndFire(on observer: AnyObject, observerBlock: @escaping (Value) -> Void) {
        observers.append(Observer(observer: observer, block: observerBlock))
        observerBlock(self.value)
    }
    
    public func remove(observer: AnyObject) {
        observers = observers.filter { $0.observer !== observer }
    }
    
    private func notifyObservers() {
        for observer in observers {
            DispatchQueue.main.async { observer.block(self.value) }
        }
    }
}

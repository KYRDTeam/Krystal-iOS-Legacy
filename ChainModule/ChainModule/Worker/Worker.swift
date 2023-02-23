//
//  Worker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class Worker: BackgroundWorker {
    
    var operations: [Operation] = []
    var queue: OperationQueue = OperationQueue()
    
    public init(operations: [Operation]) {
        self.operations = operations
        queue.maxConcurrentOperationCount = 10
    }
    
    open func prepare(completion: @escaping () -> ()) {
        completion()
    }
    
    public func asyncWaitAll(completion: (() -> ())? = nil) {
        prepare {
            let group = DispatchGroup()
            for op in self.operations {
                group.enter()
                op.completionBlock = { group.leave() }
            }
            self.queue.addOperations(self.operations, waitUntilFinished: false)
            group.notify(queue: .main) {
                completion?()
            }
        }
    }
    
    public func asyncWaitFastest(completion: @escaping () -> ()) {
        prepare {
            var isCompleted: Bool = false
            for op in self.operations {
                op.completionBlock = {
                    if !isCompleted {
                        isCompleted = true
                        completion()
                    }
                }
            }
            self.queue.addOperations(self.operations, waitUntilFinished: false)
        }
    }
    
    public func asyncWaitHighestPriority(completion: @escaping () -> ()) {
        prepare {
            let highestPriorityOp = self.operations.max { lhs, rhs in lhs.queuePriority.rawValue > rhs.queuePriority.rawValue }
            highestPriorityOp?.completionBlock = { completion() }
            self.queue.addOperations(self.operations, waitUntilFinished: false)
        }
    }
    
    public func syncByPriority(completion: @escaping () -> ()) {
        prepare {
            if self.operations.count < 2 {
                self.asyncWaitAll(completion: completion)
            } else {
                let sortedOps = self.operations.sorted(by: { lhs, rhs in lhs.queuePriority.rawValue > rhs.queuePriority.rawValue })

                for index in 1..<sortedOps.count {
                    sortedOps[index].addDependency(sortedOps[index - 1])
                }
                
                sortedOps.last?.completionBlock = { completion() }
                self.queue.addOperations(sortedOps, waitUntilFinished: false)
            }
        }
    }
    
}

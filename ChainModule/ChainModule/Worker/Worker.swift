//
//  Worker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public class Worker {
    
    var operations: [Operation] = []
    var queue: OperationQueue = OperationQueue()
    
    public init(operations: [Operation]) {
        self.operations = operations
    }
    
    public func asyncWaitAll(completion: @escaping () -> ()) {
        let group = DispatchGroup()
        for op in operations {
            group.enter()
            op.completionBlock = { group.leave() }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    public func asyncWaitFastest(completion: @escaping () -> ()) {
        var isCompleted: Bool = false
        for op in operations {
            op.completionBlock = {
                if !isCompleted {
                    isCompleted = true
                    completion()
                }
            }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    public func asyncWaitHighestPriority(completion: @escaping () -> ()) {
        let highestPriorityOp = operations.max { lhs, rhs in lhs.queuePriority.rawValue > rhs.queuePriority.rawValue }
        highestPriorityOp?.completionBlock = { completion() }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    public func syncByPriority(completion: @escaping () -> ()) {
        if operations.count < 2 {
            asyncWaitAll(completion: completion)
        } else {
            let sortedOps = operations.sorted(by: { lhs, rhs in lhs.queuePriority.rawValue > rhs.queuePriority.rawValue })

            for index in 1..<sortedOps.count {
                sortedOps[index].addDependency(sortedOps[index - 1])
            }
            
            sortedOps.last?.completionBlock = { completion() }
            queue.addOperations(sortedOps, waitUntilFinished: false)
        }
        
    }
    
}

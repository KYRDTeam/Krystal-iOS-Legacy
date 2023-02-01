//
//  Worker.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import Foundation

public protocol Worker {
    var operations: [Operation] { get }
    var queue: OperationQueue { get }
    
    func asyncWaitAll(completion: @escaping () -> ())
    func asyncWaitFastest(completion: @escaping () -> ())
    func asyncWaitHighestPriority(completion: @escaping () -> ())
    func syncByPriority(completion: @escaping () -> ())
}

public extension Worker {
    
    func asyncWaitAll(completion: @escaping () -> ()) {
        let group = DispatchGroup()
        for op in operations {
            group.enter()
            op.completionBlock = { group.leave() }
        }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    func asyncWaitFastest(completion: @escaping () -> ()) {
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
    
    func asyncWaitHighestPriority(completion: @escaping () -> ()) {
        let highestPriorityOp = operations.max { lhs, rhs in lhs.queuePriority.rawValue > rhs.queuePriority.rawValue }
        highestPriorityOp?.completionBlock = { completion() }
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    func syncByPriority(completion: @escaping () -> ()) {
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

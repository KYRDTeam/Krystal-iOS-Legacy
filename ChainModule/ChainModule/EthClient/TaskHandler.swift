//
//  TaskHandler.swift
//  ChainModule
//
//  Created by Tung Nguyen on 23/02/2023.
//

import Foundation

protocol TaskProtocol {
    func handle(completion: @escaping ((Result<Any, Error>) -> ()))
}

protocol TaskWorker {
    func asyncWaitSuccess(handlers: [TaskProtocol], completion: @escaping (Result<Any, Error>) -> ())
    func asyncWaitFastest(handlers: [TaskProtocol], completion: @escaping (Result<Any, Error>) -> ())
}

extension TaskWorker {
    func asyncWaitSuccess(handlers: [TaskProtocol], completion: @escaping (Result<Any, Error>) -> ()) {
        var completedTasksCount = 0
        var isCompleted = false
        handlers.forEach { handler in
            handler.handle { result in
                if !isCompleted {
                    switch result {
                    case .success(let data):
                        isCompleted = true
                        completion(.success(data))
                    case .failure(let error):
                        completedTasksCount += 1
                        if completedTasksCount == handlers.count {
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    func asyncWaitFastest(handlers: [TaskProtocol], completion: @escaping (Result<Any, Error>) -> ()) {
        var isCompleted: Bool = false
        handlers.forEach { handler in
            handler.handle { result in
                if !isCompleted {
                    isCompleted = true
                    completion(result)
                }
            }
        }
    }
}

//
//  InternalTransactionState.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 10/11/2022.
//

import Foundation

public enum InternalTransactionState: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .pending
    case 1:
      self = .speedup
    case 2:
      self = .cancel
    case 3:
      self = .done
    case 4:
      self = .drop
    case 5:
      self = .error
    default:
      throw CodingError.unknownValue
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .pending:
      try container.encode(0, forKey: .rawValue)
    case .speedup:
      try container.encode(1, forKey: .rawValue)
    case .cancel:
      try container.encode(2, forKey: .rawValue)
    case .done:
      try container.encode(3, forKey: .rawValue)
    case .drop:
      try container.encode(4, forKey: .rawValue)
    case .error:
      try container.encode(5, forKey: .rawValue)
    }
  }
  
  case pending
  case speedup
  case cancel
  case done
  case drop
  case error
}

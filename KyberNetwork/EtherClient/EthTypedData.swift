// Copyright DApps Platform Inc. All rights reserved.

import BigInt
import Foundation

/*
This enum is only used to support decode solidity types (represented by json values) to swift primitive types.
 */
enum SolidityJSONValue: Decodable {
    case none
    case bool(value: Bool)
    case string(value: String)
    case address(value: String)

    // we store number in 64 bit integers
    case int(value: Int64)
    case uint(value: UInt64)

    var string: String {
        switch self {
        case .none:
            return ""
        case .bool(let bool):
            return bool ? "true" : "false"
        case .string(let string):
            return string
        case .address(let address):
            return address
        case .uint(let uint):
            return "\(uint)"
        case .int(let int):
            return String(int)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(value: boolValue)
        } else if let uint = try? container.decode(UInt64.self) {
            self = .uint(value: uint)
        } else if let int = try? container.decode(Int64.self) {
            self = .int(value: int)
        } else if let string = try? container.decode(String.self) {
            if CryptoAddressValidator.isValidAddress(string) {
                self = .address(value: string)
            } else {
                self = .string(value: string)
            }
        } else {
            self = .none
        }
    }
}

struct EthTypedData: Decodable {
    //for signTypedMessage
    let type: String
    let name: String
    let value: SolidityJSONValue

    var schemaString: String {
        return "\(type) \(name)"
    }

    var schemaData: Data {
        return Data(bytes: Array(schemaString.utf8))
    }
}

private func parseIntSize(type: String, prefix: String) -> Int {
    guard type.starts(with: prefix) else {
        return -1
    }
    guard let size = Int(type.dropFirst(prefix.count)) else {
        if type == prefix {
            return 256
        }
        return -1
    }

    if size < 8 || size > 256 || size % 8 != 0 {
        return -1
    }
    return size
}

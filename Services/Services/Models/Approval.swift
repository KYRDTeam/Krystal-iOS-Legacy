//
//  Approval.swift
//  Services
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation

public struct ApprovalsResponse: Decodable {
    public private(set) var data: ApprovalsData?
}

public struct ApprovalsData: Decodable {
    public private(set) var atRisk: [String: Double]?
    public private(set) var approvals: [Approval]?
}

public struct Approval: Decodable {
    public private(set) var ownerAddress: String
    public private(set) var chainId: Int
    public private(set) var tokenAddress: String?
    public private(set) var spenderAddress: String?
    public private(set) var spenderName: String?
    public private(set) var amount: String?
    public private(set) var lastUpdateTxHash: String?
    public private(set) var symbol: String?
    public private(set) var name: String?
    public private(set) var logo: String?
    public private(set) var tag: String?
    public private(set) var decimals: Int
    public private(set) var lastUpdateTimestamp: String?
    
    public var isVerified: Bool {
        return tag == "VERIFIED"
    }
}

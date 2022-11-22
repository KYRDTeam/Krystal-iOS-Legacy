//
//  ChartDataResponse.swift
//  Services
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

public struct ChartDataResponse: Codable {
    public let timestamp: Int
    public let prices: [[Double]]
}

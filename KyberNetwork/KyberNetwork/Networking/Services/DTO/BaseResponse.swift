//
//  BaseResponse.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation

struct BaseResponse<DataType: Decodable>: Decodable {
  var timestamp: Int
  var data: DataType?
}

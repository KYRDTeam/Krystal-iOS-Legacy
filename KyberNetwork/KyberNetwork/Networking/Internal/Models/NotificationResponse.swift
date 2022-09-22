//
//  Notification.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import Foundation

struct NotificationResponseV2: Decodable {
  var page: Int
  var limit: Int
  var total: Int
  var data: [NotificationModel]
}

struct NotificationModel: Decodable {
  var id: Int
  var title: String
  var content: String
  var createdTime: String
  var userAddress: String
  var type: String
  var url: String
  var imageURL: String
  var status: String
  
  enum CodingKeys: String, CodingKey {
    case id, title, content, createdTime, userAddress, type, url, status
    case imageURL = "imageUrl"
  }
}

// MARK: - BadgeNumberResponse
struct BadgeNumberResponse: Codable {
    let data: Int
}

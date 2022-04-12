//
//  GameCampaign.swift
//  KyberGames
//
//  Created by Nguyen Tung on 12/04/2022.
//

import Foundation

struct Campaign: Decodable {
  var image: String
  var title: String
  
  static let mock: [Campaign] = [
    .init(image: "", title: ""),
    .init(image: "", title: ""),
    .init(image: "", title: ""),
  ]
}

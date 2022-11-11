//
//  EarnPoolModel.swift
//  KyberNetwork
//
//  Created by Com1 on 14/10/2022.
//

import UIKit
import Services
import Utilities

public class EarnPoolModel {
  public let token: Token
  public let chainName: String
  public let chainLogo: String
  public let chainID: Int
  public let apy: Double
  public let tvl: Double
  public let platforms: [EarnPlatform]
  
  init(json: JSONDictionary) {
    if let jsonData = json["token"] as? JSONDictionary {
      self.token = Token(dictionary: jsonData)
    } else {
      self.token = Token(name: "", symbol: "", address: "", decimals: 0, logo: "")
    }
    if let jsonData = json["chain"] as? JSONDictionary {
      self.chainName = jsonData["name"] as? String ?? ""
      self.chainLogo = jsonData["logo"] as? String ?? ""
      self.chainID = jsonData["id"] as? Int ?? 1
    } else {
      self.chainName = ""
      self.chainLogo = ""
      self.chainID = -1
    }
    self.apy = json["apy"] as? Double ?? 0
    self.tvl = json["tvl"] as? Double ?? 0
    
    var platformsArray: [EarnPlatform] = []
    if let jsonDatas = json["platforms"] as? [JSONDictionary] {
      jsonDatas.forEach { jsonData in
        platformsArray.append(EarnPlatform(json: jsonData))
      }
    }
    self.platforms = platformsArray
  }
}

public class EarnPlatform {
  public let name: String
  public let logo: String
  public let type: String
  public let desc: String
  public let apy: Double
  public let tvl: Double

  init(json: JSONDictionary) {
    self.name = json["name"] as? String ?? ""
    self.logo = json["logo"] as? String ?? ""
    self.type = json["type"] as? String ?? ""
    self.desc = json["desc"] as? String ?? ""
    self.apy = json["apy"] as? Double ?? 0
    self.tvl = json["tvl"] as? Double ?? 0
  }
}

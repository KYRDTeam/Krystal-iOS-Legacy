//
//  Portfolio.swift
//  KyberNetwork
//
//  Created by Com1 on 21/06/2022.
//

import UIKit

class Portfolio: Codable {
  var ens: String
  var id: String
  init(json: JSONDictionary) {
    self.id = json["id"] as? String ?? ""
    self.ens = json["ens"] as? String ?? ""
  }
}

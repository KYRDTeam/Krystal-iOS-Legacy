//
//  Images.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

class Images {
  static let bundle = Bundle(for: Images.self)
  
  static func image(named name: String) -> UIImage? {
    return UIImage(named: name, in: bundle, compatibleWith: nil)
  }
  
  static let challengeCheckin = Images.image(named: "challenge_checkin")!
  static let challengeRefer = Images.image(named: "challenge_refer")!
  static let challengeSend = Images.image(named: "challenge_send")!
}

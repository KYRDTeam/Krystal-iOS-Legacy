// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import RealmSwift

class IEOUser: Object {

  @objc dynamic var userID: Int = -1
  @objc dynamic var name: String = ""
  @objc dynamic var contactType: String = ""
  @objc dynamic var contactID: String = ""
  @objc dynamic var tokenType: String = ""
  @objc dynamic var expireTime: Double = 0
  @objc dynamic var accessToken: String = ""
  @objc dynamic var refreshToken: String = ""
  @objc dynamic var isSignedIn: Bool = true
  @objc dynamic var avatarURL: String = ""
  var registeredAddress: List<String> = List<String>()

  convenience init(dict: JSONDictionary) {
    self.init()
    self.userID = dict["uid"] as? Int ?? -1
    self.name = dict["name"] as? String ?? ""
    self.contactType = dict["contact_type"] as? String ?? ""
    self.contactID = dict["contact_id"] as? String ?? ""
    self.registeredAddress = List<String>()
    self.avatarURL = dict["avatar_url"] as? String ?? ""
    if let arr = dict["active_wallets"] as? [String] {
      arr.forEach { self.registeredAddress.append($0.lowercased()) }
    }
  }

  func updateToken(type: String, accessToken: String, refreshToken: String, expireTime: Double) {
    self.tokenType = type
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.expireTime = expireTime
  }

  override class func primaryKey() -> String? {
    return "userID"
  }
}

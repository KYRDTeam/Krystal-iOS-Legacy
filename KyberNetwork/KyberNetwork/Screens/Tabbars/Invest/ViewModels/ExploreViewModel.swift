//
//  ExploreViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit

enum ExploreMenuItem: CaseIterable {
  case swap
  case transfer
  case reward
  case referral
  case dapps
  case multisend
  case buyCrypto
  case promotion
  case rewardHunting
}

enum ExploreSection {
  case banners
  case menu
  case partners
}

class ExploreViewModel {
  
  var banners: Dynamic<[Asset]> = .init([])
  var menuItems: Dynamic<[ExploreMenuItem]> = .init([])
  var partners: Dynamic<[Asset]> = .init([])
  
  var sections: [ExploreSection] = [.banners, .menu, .partners]
  
}

// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KNWelcomeScreenViewModel {

  public struct KNWelcomeData {
    let jsonFileName: String
    let title: String
    let subtitle: String
    let position: Int
  }

  let dataList: [KNWelcomeData]

  init() {
      let page1 = KNWelcomeData(jsonFileName: "simplest_wallet", title: Strings.simplestWallet, subtitle: Strings.easyToUse, position: 1)
    let page2 = KNWelcomeData(jsonFileName: "dashboard", title: Strings.comprehensiveDashboard, subtitle: Strings.trackAllAssets, position: 2)
    let page3 = KNWelcomeData(jsonFileName: "trading", title: Strings.seamlessTrading, subtitle: Strings.securelySwap, position: 3)
    let page4 = KNWelcomeData(jsonFileName: "reward", title: Strings.loyaltyRewards, subtitle: Strings.getRewardOnKrystal, position: 4)
    self.dataList = [page1, page2, page3, page4]
  }

  var numberRows: Int { return self.dataList.count }

  func welcomeData(at row: Int) -> KNWelcomeData {
    return self.dataList[row]
  }
}

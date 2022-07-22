// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import KrystalWallets

struct KNWalletQRCodeViewModel {
  
  var address: KAddress {
    return AppDelegate.session.address
  }
  
  var addressString: String {
    return address.addressString
  }

  var shareText: String {
    return addressString
  }

  var copyAddressBtnTitle: String {
    return Strings.copy
  }

  var shareBtnTitle: String {
    return Strings.share
  }

  var navigationTitle: String {
    return address.name
  }
}

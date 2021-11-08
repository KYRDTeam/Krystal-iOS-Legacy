// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIDevice {

  public static let isIphone5: Bool = UIScreen.main.bounds.size.height == 568.0
  public static let isIphone6: Bool = UIScreen.main.bounds.size.height == 667
  public static let isIphone6Plus: Bool = UIScreen.main.bounds.size.height == 736
  public static let isIphoneXOrLater: Bool = UIScreen.main.bounds.size.height >= 812

}

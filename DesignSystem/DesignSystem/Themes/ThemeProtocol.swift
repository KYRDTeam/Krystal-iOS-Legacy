//
//  Theme.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 12/10/2022.
//

import UIKit

public protocol ThemeProtocol {
    var primaryColor: UIColor { get }
    var mainButtonBackgroundColor: UIColor { get }
    var mainButtonTextColor: UIColor { get }
    var secondaryButtonBackgroundColor: UIColor { get }
    var secondaryButtonTextColor: UIColor { get }
    var mainViewBackgroundColor: UIColor { get }
    var sectionBackgroundColor: UIColor { get }
    var primaryTextColor: UIColor { get }
    var secondaryTextColor: UIColor { get }
    var cancelButtonBackgroundColor: UIColor { get }
    var cancelButtonTextColor: UIColor { get }
    var popupBackgroundColor: UIColor { get }
    var separatorColor: UIColor { get }
    var headerSeparatorColor: UIColor { get }
    var errorTextColor: UIColor { get }
    var warningTextColor: UIColor { get }
    var infoTextColor: UIColor { get }
    var orangeColor: UIColor { get }
}



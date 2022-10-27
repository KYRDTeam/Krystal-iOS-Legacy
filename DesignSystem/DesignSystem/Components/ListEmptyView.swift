//
//  ListEmptyView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/09/2022.
//

import UIKit
import Utilities

public class ListEmptyView: BaseXibView {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    
    public func setup(icon: UIImage, message: String) {
        iconImageView.image = icon
        messageLabel.text = message
    }
}

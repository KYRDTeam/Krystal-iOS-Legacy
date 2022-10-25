//
//  BottomMessagePopup.swift
//  DesignSystem
//
//  Created by Tung Nguyen on 25/10/2022.
//

import UIKit
import FittedSheets

public class BottomMessagePopup: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var message: String?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = title
        messageLabel.text = message
    }
    
    public static func show(on viewController: UIViewController, title: String, message: String) {
        let vc = BottomMessagePopup.instantiateFromNib()
        vc.title = title
        vc.message = message
        let options = SheetOptions(pullBarHeight: 0)
        let sheet = SheetViewController(controller: vc, sizes: [.intrinsic], options: options)
        viewController.present(sheet, animated: true)
    }
    
}


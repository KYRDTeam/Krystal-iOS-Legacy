//
//  SignMessagePopup.swift
//  DappBrowser
//
//  Created by Tung Nguyen on 15/12/2022.
//

import UIKit
import Utilities
import FittedSheets
import KrystalWallets

class SignMessagePopup: UIViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var webUrlLabel: UILabel!
    
    var pageInfo: WebPageInfo?
    var address: KAddress!
    var message: Data!
    var onCompleted: (Data) -> () = { _ in }
    var onCancelled: () -> () = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logoImageView.loadImage(pageInfo?.icon)
        webUrlLabel.text = pageInfo?.url
        addressLabel.text = address?.addressString
        messageLabel.text = String(data: message, encoding: .utf8)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true) {
            self.onCancelled()
        }
    }
    
    @IBAction func confirmTapped(_ sender: Any) {
        guard let signature = try? EthSigner().signMessageHash(address: address, data: message, addPrefix: true) else {
            return
        }
        dismiss(animated: true) {
            self.onCompleted(signature)
        }
    }
    
    static func show(on viewController: UIViewController, address: KAddress, message: Data, pageInfo: WebPageInfo, completion: @escaping (Data) -> (), onCancelled: @escaping () -> ()) {
        let popup = SignMessagePopup.instantiateFromNib()
        popup.message = message
        popup.address = address
        popup.onCompleted = completion
        popup.onCancelled = onCancelled
        popup.pageInfo = pageInfo
        let sheet = SheetViewController(controller: popup, sizes: [.intrinsic], options: .init(pullBarHeight: 0))
        sheet.dismissOnOverlayTap = false
        viewController.present(sheet, animated: true)
    }

}

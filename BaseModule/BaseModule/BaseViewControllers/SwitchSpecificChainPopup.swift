//
//  SwitchSpecificChainPopup.swift
//  BaseModule
//
//  Created by Tung Nguyen on 24/11/2022.
//

import UIKit
import BaseWallet
import AppState
import FittedSheets

public class SwitchSpecificChainPopup: UIViewController {
  @IBOutlet weak var sourceChainImageView: UIImageView!
  @IBOutlet weak var sourceChainNameLabel: UILabel!
  @IBOutlet weak var destChainImageView: UIImageView!
  @IBOutlet weak var destChainNameLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!
  
  var sourceChain: ChainType!
  var destChain: ChainType!
  var onConfirm: (() -> ())?
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    setupViews()
  }
  
  func setupViews() {
    sourceChainImageView.image = sourceChain.squareIcon()
    destChainImageView.image = destChain.squareIcon()
    sourceChainNameLabel.text = sourceChain.chainName()
    destChainNameLabel.text = destChain.chainName()
    messageLabel.text = "Please switch to \(destChain.chainName()) to perform this action"
  }
  
  @IBAction func confirmTapped(_ sender: Any) {
    dismiss(animated: true) {
      AppState.shared.updateChain(chain: self.destChain)
      self.onConfirm?()
    }
  }
  
  public static func show(onViewController vc: UIViewController,
                          sourceChain: ChainType = AppState.shared.currentChain,
                          destChain: ChainType,
                          onConfirm: @escaping () -> ()) {
    let popup = SwitchSpecificChainPopup.instantiateFromNib()
    popup.sourceChain = sourceChain
    popup.destChain = destChain
    popup.onConfirm = onConfirm
    let sheet = SheetViewController(controller: popup, sizes: [.intrinsic], options: .init(pullBarHeight: 0))
    vc.present(sheet, animated: true)
  }
  
}

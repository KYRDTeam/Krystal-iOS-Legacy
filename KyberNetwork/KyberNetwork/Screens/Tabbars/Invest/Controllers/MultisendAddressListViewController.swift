//
//  MultisendAddressListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/02/2022.
//

import UIKit

struct MultisendAddressListViewModel {
  let items: [MultiSendItem]
}

class MultisendAddressListViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var addressesTableView: UITableView!
  
  let transitor = TransitionDelegate()
  
  let viewModel: MultisendAddressListViewModel
  
  init(viewModel: MultisendAddressListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: MultisendAddressListViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
  }
}

extension MultisendAddressListViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 555
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

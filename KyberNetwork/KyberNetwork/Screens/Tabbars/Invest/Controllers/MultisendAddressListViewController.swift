//
//  MultisendAddressListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/02/2022.
//

import UIKit

struct MultisendAddressListViewModel {
  let items: [MultiSendItem]
  
  var cellModel: [MultiSendAddressCellModel] {
    var result: [MultiSendAddressCellModel] = []
    for (index, e) in items.enumerated() {
      let vm = MultiSendAddressCellModel(item: e, index: index)
      result.append(vm)
    }
    return result
  }
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
    
    let nib = UINib(nibName: MultiSendAddressCell.className, bundle: nil)
    self.addressesTableView.register(nib, forCellReuseIdentifier: MultiSendAddressCell.cellID)
    self.addressesTableView.rowHeight = MultiSendAddressCell.cellHeight
    MixPanelManager.track("multi_send_total_addresses_pop_up_open", properties: ["screenid": "multi_send_total_addresses_pop_up"])
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
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

extension MultisendAddressListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.items.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: MultiSendAddressCell.cellID,
      for: indexPath
    ) as! MultiSendAddressCell
    let cm = self.viewModel.cellModel[indexPath.row]
    cell.updateCellModel(cm)
    return cell
  }
}

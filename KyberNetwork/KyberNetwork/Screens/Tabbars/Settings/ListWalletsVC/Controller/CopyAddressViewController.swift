//
//  CopyAddressViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/04/2022.
//

import UIKit
import Alamofire
import TrustKeystore
import KrystalWallets

class CopyAddressViewModel {
  let dataSource: [CopyAddressCellModel]
  let wallet: KWallet
  
  init(wallet: KWallet) {
    self.wallet = wallet
    self.dataSource = ChainType.getAllChain().flatMap { chain in
      return WalletManager.shared
        .getAllAddresses(walletID: wallet.id, addressType: chain.addressType)
        .map { CopyAddressCellModel(type: chain, address: $0) }
    }
  }
}

protocol CopyAddressViewControllerDelegate: class {
  func copyAddressViewController(_ controller: CopyAddressViewController, didSelect wallet: KWallet, chain: ChainType)
}

class CopyAddressViewController: KNBaseViewController {
  
  @IBOutlet weak var chainListTableView: UITableView!
  let viewModel: CopyAddressViewModel
  weak var delegate: CopyAddressViewControllerDelegate?
  
  init(viewModel: CopyAddressViewModel) {
    self.viewModel = viewModel
    super.init(nibName: CopyAddressViewController.className, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.chainListTableView.registerCellNib(CopyAddressCell.self)
    self.chainListTableView.rowHeight = 80
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
}

extension CopyAddressViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(CopyAddressCell.self, indexPath: indexPath)!
    let cm = self.viewModel.dataSource[indexPath.row]
    cell.updateCell(model: cm)
    cell.delegate = self
    return cell
  }
}

extension CopyAddressViewController: CopyAddressCellDelegate {
  func copyAddressCellDidSelectAddress(cell: CopyAddressCell, address: String) {
    UIPasteboard.general.string = address
    self.showMessageWithInterval(
      message: NSLocalizedString("address.copied", value: "Address copied", comment: "")
    )
  }
}

extension CopyAddressViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cm = self.viewModel.dataSource[indexPath.row]
    self.delegate?.copyAddressViewController(self, didSelect: viewModel.wallet, chain: cm.type)
  }
}

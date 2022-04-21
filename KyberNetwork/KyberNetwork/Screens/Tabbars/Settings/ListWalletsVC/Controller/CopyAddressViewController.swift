//
//  CopyAddressViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 14/04/2022.
//

import UIKit
import Alamofire
import TrustKeystore

class CopyAddressViewModel {
  let walletData: WalletData
  let dataSource: [CopyAddressCellModel]
  let keyStore: Keystore
  
  init(data: WalletData, keyStore: Keystore) {
    self.walletData = data
    self.keyStore = keyStore
    let allChains = ChainType.getAllChain()
    
    var result: [CopyAddressCellModel] = []
    for element in allChains {
      if element == .solana {
        if let account = keyStore.matchWithEvmAccount(address: self.walletData.address), case .success(let seeds) = self.keyStore.exportMnemonics(account: account) {
          let address = SolanaUtil.seedsToPublicKey(seeds)
          let solData = WalletData(address: address, name: "", icon: "", isBackedUp: true, isWatchWallet: false, date: Date(), chainType: .solana, storageType: .seeds, evmAddress: "")
          result.append(CopyAddressCellModel(type: element, data: solData))
        }
      } else {
        result.append(CopyAddressCellModel(type: element, data: data))
      }
    }
    
    self.dataSource = result
  }
}

class CopyAddressViewController: KNBaseViewController {
  
  @IBOutlet weak var chainListTableView: UITableView!
  let viewModel: CopyAddressViewModel
  
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

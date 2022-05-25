//
//  MiniAppListController.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit

protocol MiniAppListControllerDelegate: class {
  func didSelectAddWallet()
  func didSelectWallet(_ wallet: Wallet)
  func didSelectManageWallet()
  func didSelectAddChainWallet(chainType: ChainType)
}

class MiniAppListController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  weak var delegate: MiniAppListControllerDelegate?
  var dataSource: [MiniApp]
  var session: KNSession
  var listTitle: String
  
  init(dataSource: [MiniApp], session: KNSession, title: String) {
    self.dataSource = dataSource
    self.session = session
    self.listTitle = title
    super.init(nibName: MiniAppListController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerCellNib(MiniAppDetailCell.self)
    self.titleLabel.text = listTitle
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension MiniAppListController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(MiniAppDetailCell.self, indexPath: indexPath)!
    let miniApp = self.dataSource[indexPath.row]
    cell.titleLabel.text = miniApp.name
    if let url = URL(string: miniApp.icon) {
      cell.icon.setImage(with: url, placeholder: nil)
    }
    cell.detailLabel.text = miniApp.description
    cell.configure(voteCount: miniApp.voteCount, needShowVote: listTitle == "Vote")
    return cell
  }
}

extension MiniAppListController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let miniApp = self.dataSource[indexPath.row]
    let detaiVC = MiniAppDetailViewController(miniApp: miniApp, session: self.session)
    detaiVC.delegate = self
    self.show(detaiVC, sender: nil)
  }
}

extension MiniAppListController: MiniAppDetailDelegate {
  func dAppCoordinatorDidSelectAddWallet() {
    self.delegate?.didSelectAddWallet()
  }
  
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.didSelectWallet(wallet)
  }
  
  func dAppCoordinatorDidSelectManageWallet() {
    self.delegate?.didSelectManageWallet()
  }
  
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.didSelectAddChainWallet(chainType: chainType)
  }
}

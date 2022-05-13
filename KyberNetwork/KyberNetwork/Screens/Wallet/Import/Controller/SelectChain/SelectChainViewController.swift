//
//  SelectChainViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 14/04/2022.
//

import UIKit

enum SelectChainEvent {
  case back
  case importMultiChain
  case importEVM(type: ChainType)
  case importSolana
}

protocol SelectChainDelegate: class {
  func selectChainViewController(_ controller: SelectChainViewController, run event: SelectChainEvent)
}

class SelectChainViewController: KNBaseViewController {
  weak var delegate: SelectChainDelegate?
  @IBOutlet weak var tableView: UITableView!
  var selectedChain: ChainType?
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  func setupUI() {
    self.tableView.registerCellNib(SwitchChainCell.self)
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.delegate?.selectChainViewController(self, run: .back)
  }
}

extension SelectChainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return ChainType.getAllChain().count + 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwitchChainCell.self, indexPath: indexPath)!
    cell.iconHeightConstraint.constant = 24.0
    cell.contentView.backgroundColor = UIColor(named: "mainViewBgColor")!
    if indexPath.row == 0 {
      cell.chainIcon.image = UIImage(named: "multichain_icon")
      cell.chainNameLabel.text = "Multi-chain wallet"
    } else {
      let chain = ChainType.getAllChain()[indexPath.row - 1]
      cell.configCell(chain: chain, isSelected: self.selectedChain == chain)
    }
    cell.selectionStyle = .none
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 54.0
  }
}

extension SelectChainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.row == 0 {
      // config multi-chain cell
      self.delegate?.selectChainViewController(self, run: .importMultiChain)
    } else {
      let chain = ChainType.getAllChain()[indexPath.row - 1]
      self.selectedChain = chain
      self.delegate?.selectChainViewController(self, run: chain == .solana ? .importSolana : .importEVM(type: chain))
    }
  }
}

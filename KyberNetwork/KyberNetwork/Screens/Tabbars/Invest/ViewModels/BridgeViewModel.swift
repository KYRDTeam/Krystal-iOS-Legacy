//
//  BridgeViewModel.swift
//  KyberNetwork
//
//  Created by Com1 on 20/05/2022.
//

import UIKit
import BigInt

enum FromSectionRows: CaseIterable {
  case selectChainRow
  case poolInfoRow
  case selectTokenRow
  
  static func sectionRows(showPoolInfo: Bool) -> [FromSectionRows] {
    var allRows = FromSectionRows.allCases
    if !showPoolInfo {
      allRows = allRows.filter { $0 != .poolInfoRow }
    }
    return allRows
  }
}

enum ToSectionRows: CaseIterable {
  case selectChainRow
  case poolInfoRow
  case selectTokenRow
  case sendToRow
  case addressRow
  case reminderRow
  case errorRow
  case swapRow
  
  static func sectionRows(showPoolInfo: Bool, showSendAddress: Bool, showReminder: Bool, showError: Bool) -> [ToSectionRows] {
    var allRows = ToSectionRows.allCases
    if !showPoolInfo {
      allRows = allRows.filter { $0 != .poolInfoRow }
    }
    if !showSendAddress {
      allRows = allRows.filter { $0 != .addressRow }
    }
    if !showReminder {
      allRows = allRows.filter { $0 != .reminderRow }
    }
    if !showError {
      allRows = allRows.filter { $0 != .errorRow }
    }
    return allRows
  }
}
class BridgeViewModel {
  fileprivate(set) var wallet: Wallet
  var showFromPoolInfo: Bool = false
  var showToPoolInfo: Bool = false
  var showSendAddress: Bool = false
  var showReminder: Bool = true
  var showError: Bool = false
  
  var selectSourceChainBlock: (() -> Void)?
  var selectSourceTokenBlock: (() -> Void)?
  var selectDestChainBlock: (() -> Void)?
  var selectDestTokenBlock: (() -> Void)?
  
  var currentSourceChain: ChainType?
  var currentSourceToken: TokenObject?
  var currentDestChain: ChainType?
  
  
  var currentDestTokenAddress: String = ""
  var currentDestTokenSymbol: String = ""

  init(wallet: Wallet) {
    self.wallet = wallet
  }

  func updateWallet(_ wallet: Wallet) {
    self.wallet = wallet
  }

  func fromDataSource() -> [FromSectionRows] {
    return FromSectionRows.sectionRows(showPoolInfo: self.showFromPoolInfo)
  }
  
  func toDataSource() -> [ToSectionRows] {
    return ToSectionRows.sectionRows(showPoolInfo: self.showToPoolInfo, showSendAddress: self.showSendAddress, showReminder: self.showReminder, showError: self.showError)
  }

  func numberOfSection() -> Int {
    return 2
  }
  
  func numberOfRows(section: Int) -> Int {
    if section == 0 {
      return self.fromDataSource().count
    }
    return self.toDataSource().count
  }
  
  func viewForHeader(section: Int) -> UIView {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 32))
    view.backgroundColor = UIColor(named: "mainViewBgColor")!
    let label = UILabel(frame: CGRect(x: 49, y: 0, width: 40, height: 24))
    label.text = section == 0 ? "From" : "To"
    label.textColor = UIColor(named: "textWhiteColor")!
    view.addSubview(label)
    return view
  }
  
  func viewForFooter() -> UIView {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 80))
    view.backgroundColor = UIColor(named: "mainViewBgColor")!
    let icon = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.size.width - 24) / 2, y: 20, width: 24, height: 24))
    icon.image = UIImage(named: "circle_arrow_down_icon")
    view.addSubview(icon)
    return view
  }
  
  func cellForRows(tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      switch self.fromDataSource()[indexPath.row] {
      case .selectChainRow:
        let cell = tableView.dequeueReusableCell(SelectChainCell.self, indexPath: indexPath)!
        cell.nameLabel.text = KNGeneralProvider.shared.currentChain.chainName()
        cell.selectionBlock = self.selectSourceChainBlock
        cell.arrowIcon.isHidden = false
        return cell
      case .poolInfoRow:
        let cell = tableView.dequeueReusableCell(ChainInfoCell.self, indexPath: indexPath)!
        return cell
      case .selectTokenRow:
        let cell = tableView.dequeueReusableCell(SelectTokenCell.self, indexPath: indexPath)!
        cell.selectTokenBlock = self.selectSourceTokenBlock
        if let currentSourceToken = self.currentSourceToken {
          cell.selectTokenButton.setTitle(currentSourceToken.symbol, for: .normal)
          let bal: BigInt = currentSourceToken.getBalanceBigInt()
          let string = bal.string(
            decimals: currentSourceToken.decimals,
            minFractionDigits: 0,
            maxFractionDigits: min(currentSourceToken.decimals, 5)
          )
          if let double = Double(string.removeGroupSeparator()), double == 0 {
            cell.balanceLabel.text = "0"
          } else {
            cell.balanceLabel.text = "\(string.prefix(15)) \(currentSourceToken.symbol)"
          }
          
        } else {
          cell.selectTokenButton.setTitle("Select", for: .normal)
          cell.balanceLabel.text = "0"
        }
        return cell
      }
    } else {
      switch self.toDataSource()[indexPath.row] {
      case .selectChainRow:
        let cell = tableView.dequeueReusableCell(SelectChainCell.self, indexPath: indexPath)!
        cell.nameLabel.text = ""
        cell.arrowIcon.isHidden = false
        cell.selectionBlock = self.selectDestChainBlock
        if let currentDestChain = self.currentDestChain {
          cell.nameLabel.text = currentDestChain.chainName()
        }
        return cell
      case .poolInfoRow:
        let cell = tableView.dequeueReusableCell(ChainInfoCell.self, indexPath: indexPath)!
        return cell
      case .selectTokenRow:
        let cell = tableView.dequeueReusableCell(SelectTokenCell.self, indexPath: indexPath)!
        cell.selectTokenBlock = self.selectDestTokenBlock
        cell.balanceLabel.text = ""
        cell.selectTokenButton.setTitle(self.currentDestTokenSymbol, for: .normal)
        
        return cell
      case .sendToRow:
        let cell = tableView.dequeueReusableCell(BridgeSendToCell.self, indexPath: indexPath)!
        return cell
      case .addressRow:
        let cell = tableView.dequeueReusableCell(SelectChainCell.self, indexPath: indexPath)!
        cell.arrowIcon.isHidden = true
        cell.nameLabel.text = ""
        return cell
      case .reminderRow:
        let cell = tableView.dequeueReusableCell(BridgeReminderCell.self, indexPath: indexPath)!
        return cell
      case .errorRow:
        return UITableViewCell()
      case .swapRow:
          let cell = tableView.dequeueReusableCell(BridgeSwapButtonCell.self, indexPath: indexPath)!
          return cell
      }
    }
  }
}

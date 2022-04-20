// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTransactionFilterViewControllerDelegate: class {
  func transactionFilterViewController(_ controller: KNTransactionFilterViewController, apply conditions: [FilterCondition])
}

class KNTransactionFilterViewController: KNBaseViewController {
  
  fileprivate let kFilterTokensTableViewCellID: String = "kFilterTokensTableViewCellID"
  fileprivate var viewModel: KNTransactionFilterViewModel
  
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var collectionView: UICollectionView!
  
  //  @IBOutlet weak var timeTextLabel: UILabel!
  //  @IBOutlet weak var fromTextField: UITextField!
  //  @IBOutlet weak var toTextField: UITextField!
  
  //  @IBOutlet weak var transactionTypeTextLabel: UILabel!
  
  //  @IBOutlet weak var sendButton: UIButton!
  //  @IBOutlet weak var receiveButton: UIButton!
  //  @IBOutlet weak var swapButton: UIButton!
  //  @IBOutlet weak var approveButton: UIButton!
  //  @IBOutlet weak var withdrawButton: UIButton!
  //  @IBOutlet weak var tradeButton: UIButton!
  //  @IBOutlet weak var contractInteractionButton: UIButton!
  //  @IBOutlet weak var claimRewardButton: UIButton!
  //  @IBOutlet weak var selectButton: UIButton!
  //  @IBOutlet weak var tokenTextLabel: UILabel!
  //  @IBOutlet weak var tokensTableView: UITableView!
  //  @IBOutlet weak var tokensTableViewHeightConstraint: NSLayoutConstraint!
  //  @IBOutlet weak var tokensViewActionButton: UIButton!
  //  @IBOutlet weak var toDateTimeView: UIView!
  //  @IBOutlet weak var fromDateTimeView: UIView!
  //  @IBOutlet weak var bottomPaddingForButtonConstraint: NSLayoutConstraint!
  
  //  @IBOutlet var separatorViews: [UIView]!
  
  enum Section {
    case timeRange
    case types
    case tokens
  }
  
  let sections: [Section] = [.timeRange, .types, .tokens]
  
  weak var delegate: KNTransactionFilterViewControllerDelegate?
  
  init(viewModel: KNTransactionFilterViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTransactionFilterViewController.className, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navTitleLabel.text = "History Filter".toBeLocalised()
    //    self.timeTextLabel.text = "Time".toBeLocalised()
    //
    //    self.transactionTypeTextLabel.text = "Transaction Type".toBeLocalised()
    //    self.sendButton.setTitle(NSLocalizedString("transfer", value: "Transfer", comment: ""), for: .normal)
    //    self.receiveButton.setTitle(NSLocalizedString("receive", value: "Receive", comment: ""), for: .normal)
    //    self.swapButton.setTitle(NSLocalizedString("swap", value: "Swap", comment: ""), for: .normal)
    //    self.tokenTextLabel.text = "Token".toBeLocalised()
    //
    //    let nib = UINib(nibName: KNTransactionFilterTableViewCell.className, bundle: nil)
    //    self.tokensTableView.register(nib, forCellReuseIdentifier: kFilterTokensTableViewCellID)
    //    self.tokensTableView.rowHeight = 48.0
    //    self.tokensTableView.delegate = self
    //    self.tokensTableView.dataSource = self
    //    self.tokensTableView.reloadData()
    //    self.tokensTableView.allowsSelection = false
    //
    //    self.fromTextField.inputView = self.fromDatePicker
    //    self.fromTextField.delegate = self
    //    self.toTextField.inputView = self.toDatePicker
    //    self.toTextField.delegate = self
    //
    //    self.bottomPaddingForButtonConstraint.constant = 24.0 + self.bottomPaddingSafeArea()
    //
    //    self.updateUI()
    self.setupCollectionView()
    self.configUI()
  }
  
  func setupCollectionView() {
    collectionView.registerCellNib(KNTransactionFilterTimeRangeCell.self)
    collectionView.registerCellNib(KNTransactionFilterTextCell.self)
    
    collectionView.delegate = self
    collectionView.dataSource = self
    let layout = TagFlowLayout()
    layout.estimatedItemSize = CGSize(width: 140, height: 36)
    collectionView.collectionViewLayout = layout
  }
  
  fileprivate func configUI() {
    
  }
  
  //  fileprivate func updateUI(isUpdatingTokens: Bool = true) {
  //    UIView.animate(withDuration: 0.16) {
  //      self.selectButton.setTitle(
  //        self.viewModel.isSelectAll ? "Deselect All".toBeLocalised() : "Select All".toBeLocalised(),
  //        for: .normal
  //      )
  //      if isUpdatingTokens {
  //        let btnTitle: String = self.viewModel.isSeeMore ? NSLocalizedString("see.less", value: "See less", comment: "") : NSLocalizedString("see.more", value: "See more", comment: "")
  //        self.tokensViewActionButton.setTitle(
  //          btnTitle,
  //          for: .normal
  //        )
  //      }
  //      if self.viewModel.isSend {
  //        self.sendButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.sendButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.sendButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.sendButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //      if self.viewModel.isReceive {
  //        self.receiveButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.receiveButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.receiveButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.receiveButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //      if self.viewModel.isSwap {
  //        self.swapButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.swapButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.swapButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.swapButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //      if self.viewModel.isApprove {
  //        self.approveButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.approveButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.approveButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.approveButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //      if self.viewModel.isWithdraw {
  //        self.withdrawButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.withdrawButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.withdrawButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.withdrawButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //      if self.viewModel.isTrade {
  //        self.tradeButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.tradeButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.tradeButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.tradeButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //
  //      if self.viewModel.isContractInteraction {
  //        self.contractInteractionButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.contractInteractionButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.contractInteractionButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.contractInteractionButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //
  //      if self.viewModel.isClaimReward {
  //        self.claimRewardButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
  //        self.claimRewardButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
  //      } else {
  //        self.claimRewardButton.backgroundColor = UIColor(named: "navButtonBgColor")
  //        self.claimRewardButton.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
  //      }
  //
  //      if let date = self.viewModel.from {
  //        self.fromDatePicker.setDate(date, animated: false)
  //        self.fromDatePickerDidChange(self.fromDatePicker)
  //      } else {
  //        self.fromTextField.text = ""
  //      }
  //      if let date = self.viewModel.to {
  //        self.toDatePicker.setDate(date, animated: false)
  //        self.toDatePickerDidChange(self.toDatePicker)
  //      } else {
  //        self.toTextField.text = ""
  //      }
  //      if isUpdatingTokens {
  //        self.tokensTableViewHeightConstraint.constant = {
  //          let numberRows = self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 3
  //          return CGFloat(numberRows) * self.tokensTableView.rowHeight
  //        }()
  //        self.tokensTableView.reloadData()
  //      }
  //      if self.viewModel.supportedTokens.isEmpty {
  //        self.tokenTextLabel.isHidden = true
  //        self.selectButton.isHidden = true
  //        self.tokensTableView.isHidden = true
  //        self.tokensViewActionButton.isHidden = true
  //        self.separatorViews.forEach { view in
  //          view.isHidden = true
  //        }
  //      } else {
  //        self.tokenTextLabel.isHidden = false
  //        self.selectButton.isHidden = false
  //        self.tokensTableView.isHidden = false
  //        self.tokensViewActionButton.isHidden = false
  //        self.separatorViews.forEach { view in
  //          view.isHidden = false
  //        }
  //      }
  //      self.view.layoutIfNeeded()
  //    }
  //  }
  
  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
  
  //  @IBAction func sendButtonPressed(_ sender: Any) {
  //    self.viewModel.updateIsSend(!self.viewModel.isSend)
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func receiveButtonPressed(_ sender: Any) {
  //    self.viewModel.updateIsReceive(!self.viewModel.isReceive)
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func swapButtonPressed(_ sender: Any) {
  //    self.viewModel.updateIsSwap(!self.viewModel.isSwap)
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func selectButtonPressed(_ sender: Any) {
  //    self.viewModel.updateSelectAll(!self.viewModel.isSelectAll)
  //    self.updateUI()
  //  }
  //
  //  @IBAction func approveButtonPressed(_ sender: UIButton) {
  //    self.viewModel.isApprove = !self.viewModel.isApprove
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func withdrawButtonPressed(_ sender: UIButton) {
  //    self.viewModel.isWithdraw = !self.viewModel.isWithdraw
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func tradeButtonPressed(_ sender: UIButton) {
  //    self.viewModel.isTrade = !self.viewModel.isTrade
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func contractInteractionButtonPressed(_ sender: UIButton) {
  //    self.viewModel.isContractInteraction = !self.viewModel.isContractInteraction
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  @IBAction func claimRewardButtonTapped(_ sender: Any) {
  //    self.viewModel.isClaimReward = !self.viewModel.isClaimReward
  //    self.updateUI(isUpdatingTokens: false)
  //  }
  //
  //  // See more/less
  //  @IBAction func tokensActionButtonPressed(_ sender: Any) {
  //    self.viewModel.isSeeMore = !self.viewModel.isSeeMore
  //    self.updateUI()
  //  }
  
  //  @objc func fromDatePickerDidChange(_ sender: UIDatePicker) {
  //    let dob = DateFormatterUtil.shared.kycDateFormatter.string(from: self.fromDatePicker.date)
  //    self.fromTextField.text = dob
  //    self.viewModel.updateFrom(date: self.fromDatePicker.date)
  //    if self.toDatePicker.date < self.fromDatePicker.date {
  //      self.toDatePicker.setDate(self.fromDatePicker.date, animated: false)
  //      self.toDatePickerDidChange(self.toDatePicker)
  //      self.viewModel.updateTo(date: self.toDatePicker.date)
  //    }
  //  }
  //
  //  @objc func toDatePickerDidChange(_ sender: UIDatePicker) {
  //    let dob = DateFormatterUtil.shared.kycDateFormatter.string(from: self.toDatePicker.date)
  //    self.toTextField.text = dob
  //    self.viewModel.updateTo(date: self.toDatePicker.date)
  //    if self.toDatePicker.date < self.fromDatePicker.date {
  //      self.fromDatePicker.setDate(self.toDatePicker.date, animated: false)
  //      self.fromDatePickerDidChange(self.toDatePicker)
  //      self.viewModel.updateFrom(date: self.fromDatePicker.date)
  //    }
  //  }
  
  @IBAction func resetButtonPressed(_ sender: Any) {
    self.viewModel.reset()
    self.collectionView.reloadData()
  }
  
  @IBAction func applyButtonPressed(_ sender: Any) {
    //    let filter = KNTransactionFilter(
    //      from: self.viewModel.from,
    //      to: self.viewModel.to,
    //      isSend: self.viewModel.isSend,
    //      isReceive: self.viewModel.isReceive,
    //      isSwap: self.viewModel.isSwap,
    //      isApprove: self.viewModel.isApprove,
    //      isWithdraw: self.viewModel.isWithdraw,
    //      isTrade: self.viewModel.isTrade,
    //      isContractInteraction: self.viewModel.isContractInteraction,
    //      isClaimReward: self.viewModel.isClaimReward,
    //      tokens: self.viewModel.tokens
    //    )
    //    self.navigationController?.popViewController(animated: true, completion: {
    //      self.delegate?.transactionFilterViewController(self, apply: filter)
    //    })
  }
  
  //  @IBAction func tapFromTextField(_ sender: UITapGestureRecognizer) {
  //    self.fromTextField.becomeFirstResponder()
  //  }
  //
  //  @IBAction func tapToTextField(_ sender: UITapGestureRecognizer) {
  //    self.toTextField.becomeFirstResponder()
  //  }
  
}

//extension KNTransactionFilterViewController: UITableViewDelegate {
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    tableView.deselectRow(at: indexPath, animated: false)
//  }
//}
//
//extension KNTransactionFilterViewController: UITableViewDataSource {
//  func numberOfSections(in tableView: UITableView) -> Int {
//    return 1
//  }
//
//  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    if self.viewModel.supportedTokens.count <= 4 {
//      return 1
//    } else {
//      return self.viewModel.isSeeMore ? (self.viewModel.supportedTokens.count + 3) / 4 : 2
//    }
//  }
//
//  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
//    return UIView()
//  }
//
//  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    let cell = tableView.dequeueReusableCell(withIdentifier: kFilterTokensTableViewCellID, for: indexPath) as! KNTransactionFilterTableViewCell
//    if self.viewModel.supportedTokens.count <= 4 {
//      cell.updateCell(with: self.viewModel.supportedTokens, selectedTokens: self.viewModel.tokens)
//    } else {
//      let data = Array(self.viewModel.supportedTokens[indexPath.row * 4..<min(indexPath.row * 4 + 4, self.viewModel.supportedTokens.count)])
//      cell.updateCell(with: data, selectedTokens: self.viewModel.tokens)
//    }
//    cell.delegate = self
//    return cell
//  }
//}
//
//extension KNTransactionFilterViewController: KNTransactionFilterTableViewCellDelegate {
//  func transactionFilterTableViewCell(_ cell: KNTransactionFilterTableViewCell, select token: String) {
//    self.viewModel.selectTokenSymbol(token)
//    self.tokensTableView.reloadData()
//  }
//}

//extension KNTransactionFilterViewController: UITextFieldDelegate {
//  func textFieldDidBeginEditing(_ textField: UITextField) {
//    if textField == self.fromTextField && (self.fromTextField.text ?? "").isEmpty {
//      self.fromDatePickerDidChange(self.fromDatePicker)
//    }
//    if textField == self.toTextField && (self.toTextField.text ?? "").isEmpty {
//      self.toDatePickerDidChange(self.toDatePicker)
//    }
//  }
//}

extension KNTransactionFilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return sections.count
  }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionType = sections[section]
    switch sectionType {
    case .timeRange:
      return 1
    case .types:
      return viewModel.allTypes.count
    case .tokens:
      return viewModel.displayTokens.count
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let sectionType = sections[indexPath.section]
    switch sectionType {
    case .timeRange:
      let cell = collectionView.dequeueReusableCell(KNTransactionFilterTimeRangeCell.self, indexPath: indexPath)!
      return cell
    case .types:
      let cell = collectionView.dequeueReusableCell(KNTransactionFilterTextCell.self, indexPath: indexPath)!
      let type = viewModel.allTypes[indexPath.item]
      cell.configure(text: viewModel.title(forTransactionType: type), isSelected: viewModel.selectedTypes.contains(type))
      return cell
    case .tokens:
      let cell = collectionView.dequeueReusableCell(KNTransactionFilterTextCell.self, indexPath: indexPath)!
      let token = viewModel.displayTokens[indexPath.item]
      cell.configure(text: token, isSelected: viewModel.selectedTokens.contains(token))
      return cell
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let sectionType = sections[indexPath.section]
    switch sectionType {
    case .timeRange:
      return
    case .types:
      viewModel.onSelectTypeAt(index: indexPath.item)
      collectionView.reloadItems(at: [indexPath])
    case .tokens:
      viewModel.onSelectTokenAt(index: indexPath.item)
      collectionView.reloadItems(at: [indexPath])
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 16, left: 21, bottom: 16, right: 21)
  }
  
}

class Row {
  var attributes = [UICollectionViewLayoutAttributes]()
  var spacing: CGFloat = 0
  
  init(spacing: CGFloat) {
    self.spacing = spacing
  }
  
  func add(attribute: UICollectionViewLayoutAttributes) {
    attributes.append(attribute)
  }
  
  func tagLayout(collectionViewWidth: CGFloat) {
    let padding = 10
    var offset = padding
    for attribute in attributes {
      attribute.frame.origin.x = CGFloat(offset)
      offset += Int(attribute.frame.width + spacing)
    }
  }
}

class TagFlowLayout: UICollectionViewFlowLayout {
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let attributes = super.layoutAttributesForElements(in: rect) else {
      return nil
    }
    
    var rows = [Row]()
    var currentRowY: CGFloat = -1
    
    for attribute in attributes {
      if currentRowY != attribute.frame.origin.y {
        currentRowY = attribute.frame.origin.y
        rows.append(Row(spacing: 10))
      }
      rows.last?.add(attribute: attribute)
    }
    
    rows.forEach {
      $0.tagLayout(collectionViewWidth: collectionView?.frame.width ?? 0)
    }
    return rows.flatMap { $0.attributes }
  }
}

//
//  MultiSendApproveViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/02/2022.
//

import UIKit
import BigInt
import Utilities

enum MultiSendApproveViewEvent {
  case openGasPriceSelect(gasLimit: BigInt, baseGasLimit: BigInt, selectType: KNSelectedGasPriceType, advancedGasLimit: String?, advancedPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?)
  case dismiss
  case approve(items: [ApproveMultiSendItem], isApproveUnlimit: Bool, settings: ConfirmAdvancedSetting, estNoTx: Int)
  case done
  case estimateGas(items: [ApproveMultiSendItem])
}

protocol MultiSendApproveViewControllerDelegate: class {
  func multiSendApproveVieController(_ controller: MultiSendApproveViewController, run event: MultiSendApproveViewEvent)
}

class MultiSendApproveViewModel {
  fileprivate(set) var selectedGasPriceType: KNSelectedGasPriceType = .medium
  fileprivate(set) var gasPrice: BigInt
  fileprivate(set) var gasLimit: BigInt
  fileprivate(set) var baseGasLimit: BigInt
  
  fileprivate(set) var tokens: [Token]
  fileprivate(set) var items: [ApproveMultiSendItem]
  
  var cellModels: [ApproveTokenCellModel]
  var isApproveUnlimit: Bool = false
  
  func updateStartApprove() {
    self.cellModels.forEach { element in
      element.state = .start
    }
  }
  
  var advancedGasLimit: String? {
    didSet {
      if self.advancedGasLimit != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxPriorityFee: String? {
    didSet {
      if self.advancedMaxPriorityFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedMaxFee: String? {
    didSet {
      if self.advancedMaxFee != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }

  var advancedNonce: String? {
    didSet {
      if self.advancedNonce != nil {
        self.selectedGasPriceType = .custom
      }
    }
  }
  
  var maxGasLimit: BigInt {
    let all = self.gasLimits.map { element in
      return element.1
    }
    return all.max() ?? KNGasConfiguration.approveTokenGasLimitDefault
  }

  let allowance: [Token: BigInt]
  var gasLimits: [(ApproveMultiSendItem, BigInt)] {
    didSet {
      self.gasLimit = self.maxGasLimit
    }
  }

  init(
    items: [ApproveMultiSendItem],
    gasPrice: BigInt = KNGasCoordinator.shared.defaultKNGas,
    allowances: [Token: BigInt]
  ) {
    self.items = items
    self.tokens = items.map({ item in
      return item.1
    })
    self.gasPrice = gasPrice
    self.gasLimit = KNGasConfiguration.approveTokenGasLimitDefault
    self.baseGasLimit = KNGasConfiguration.approveTokenGasLimitDefault
    let cms = items.map { element in
      return ApproveTokenCellModel(item: element)
    }
    self.cellModels = cms
    self.allowance = allowances
    self.gasLimits = items.map({ element in
      return (element, KNGasConfiguration.approveTokenGasLimitDefault)
    })
  }

  lazy var estNoTx: Int = {
    var count = 0
    self.tokens.forEach { element in
      if let remainAllowance = self.allowance[element], !remainAllowance.isZero {
        count += 1
      }
      count += 1
    }
    
    return count
  }()

  var transactionFeeETHString: String {
    let fee: BigInt = {
      return self.gasPrice * self.gasLimit
    }()
    let total = fee * BigInt(self.estNoTx)
    return "\(NumberFormatUtils.gasFeeFormat(number: total)) \(KNGeneralProvider.shared.quoteToken)"
  }

  var transactionFeeUSDString: String {
    let fee: BigInt = {
      return self.gasPrice * self.gasLimit
    }()
    let total = fee * BigInt(self.estNoTx)
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = total * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }

  var transactionGasPriceString: String {
    let gasPriceText = self.gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
    )
    let totalGasLimit = BigInt(self.estNoTx) * self.gasLimit
    let gasLimitText = EtherNumberFormatter.short.string(from: totalGasLimit, decimals: 0)
    
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
  
  func updateSelectedGasPriceType(_ type: KNSelectedGasPriceType) {
    self.selectedGasPriceType = type
    switch type {
    case .fast: self.gasPrice = KNGasCoordinator.shared.fastKNGas
    case .medium: self.gasPrice = KNGasCoordinator.shared.standardKNGas
    case .slow: self.gasPrice = KNGasCoordinator.shared.lowKNGas
    case .custom:
      if let customGasPrice = self.advancedMaxFee?.shortBigInt(units: UnitConfiguration.gasPriceUnit),
          let customGasLimitString = self.advancedGasLimit,
          let customGasLimit = BigInt(customGasLimitString) {
        self.gasPrice = customGasPrice
        self.gasLimit = customGasLimit
      }
    default: return
    }
  }

  func updateGasPrice(_ gasPrice: BigInt) {
    self.gasPrice = gasPrice
  }
  
  func resetAdvancedSettings() {
    self.advancedGasLimit = nil
    self.advancedMaxPriorityFee = nil
    self.advancedMaxFee = nil
    self.advancedNonce = nil
    if self.selectedGasPriceType == .custom {
      self.selectedGasPriceType = .medium
    }
  }
  
  var customSetting: ConfirmAdvancedSetting {
    return ConfirmAdvancedSetting(gasPrice: self.gasPrice.description, gasLimit: self.gasLimit.description, advancedGasLimit: self.advancedGasLimit, advancedPriorityFee: self.advancedMaxPriorityFee, avancedMaxFee: self.advancedMaxFee, advancedNonce: Int(self.advancedNonce ?? ""))
  }
  
  var isDoneApprove: Bool {
    let found = self.cellModels.first { element in
      return element.state != .done
    }
    
    return found == nil
  }
}

class MultiSendApproveViewController: KNBaseViewController {
  
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainLabel: UILabel!
  
  @IBOutlet weak var option1Button: UIButton!
  @IBOutlet weak var option2Button: UIButton!
  
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  
  @IBOutlet weak var tokensTableViewHeightContraint: NSLayoutConstraint!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var approveButton: UIButton!

  @IBOutlet weak var tokensTableView: UITableView!
  let transitor = TransitionDelegate()
  
  let viewModel: MultiSendApproveViewModel
  
  weak var delegate: MultiSendApproveViewControllerDelegate?
  
  init(viewModel: MultiSendApproveViewModel) {
    self.viewModel = viewModel
    super.init(nibName: MultiSendApproveViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    setupChainInfo()
    let nib = UINib(nibName: ApproveTokenCell.className, bundle: nil)
    self.tokensTableView.register(nib, forCellReuseIdentifier: ApproveTokenCell.cellID)
    self.tokensTableView.rowHeight = ApproveTokenCell.cellHeight
    self.tokensTableViewHeightContraint.constant = CGFloat(self.viewModel.cellModels.count) * ApproveTokenCell.cellHeight
    self.updateUIForCheckBox()
    self.updateGasFeeUI()
    self.backButton.rounded(radius: 16)
    self.approveButton.rounded(radius: 16)

    self.delegate?.multiSendApproveVieController(self, run: .estimateGas(items: self.viewModel.items))
  }
  
  func setupChainInfo() {
    chainIcon.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel.text = KNGeneralProvider.shared.currentChain.chainName()
  }
  
  private func updateUIForCheckBox() {
    let selectedWidth: CGFloat = 5.0
    let normalWidth: CGFloat = 1.0
    
    self.option1Button.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.isApproveUnlimit == false ? selectedWidth : normalWidth,
      radius: self.option1Button.frame.height / 2.0
    )
    
    self.option2Button.rounded(
      color: UIColor(named: "buttonBackgroundColor")!,
      width: self.viewModel.isApproveUnlimit == true ? selectedWidth : normalWidth,
      radius: self.option2Button.frame.height / 2.0
    )
  }
  
  fileprivate func updateGasFeeUI() {
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    self.gasPriceTextLabel.text = self.viewModel.transactionGasPriceString
  }
  
  @IBAction func editButtonTapped(_ sender: UIButton) {
    self.delegate?.multiSendApproveVieController(self, run: .openGasPriceSelect(gasLimit: self.viewModel.gasLimit, baseGasLimit: self.viewModel.baseGasLimit, selectType: self.viewModel.selectedGasPriceType, advancedGasLimit: self.viewModel.advancedGasLimit, advancedPriorityFee: self.viewModel.advancedMaxPriorityFee, advancedMaxFee: self.viewModel.advancedMaxFee, advancedNonce: self.viewModel.advancedNonce))
  }
  
  @IBAction func approveButtonTapped(_ sender: UIButton) {
    self.viewModel.updateStartApprove()
    self.tokensTableView.reloadData()
    self.delegate?.multiSendApproveVieController(self, run: .approve(items: self.viewModel.items, isApproveUnlimit: self.viewModel.isApproveUnlimit, settings: self.viewModel.customSetting, estNoTx: self.viewModel.estNoTx))
  }
  
  @IBAction func checkBox1Tapped(_ sender: UIButton) {
    guard self.viewModel.isApproveUnlimit else { return }
    self.viewModel.isApproveUnlimit = false
    self.updateUIForCheckBox()
  }
  
  @IBAction func checkBox2Tapped(_ sender: UIButton) {
    guard !self.viewModel.isApproveUnlimit else { return }
    self.viewModel.isApproveUnlimit = true
    self.updateUIForCheckBox()
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      self.delegate?.multiSendApproveVieController(self, run: .dismiss)
    })
  }
  
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: {
      self.delegate?.multiSendApproveVieController(self, run: .dismiss)
    })
  }

  @IBAction func helpButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
  
  func coordinatorDidUpdateAdvancedSettings(gasLimit: String, maxPriorityFee: String, maxFee: String) {
    self.viewModel.advancedGasLimit = gasLimit
    self.viewModel.advancedMaxPriorityFee = maxPriorityFee
    self.viewModel.advancedMaxFee = maxFee
    self.viewModel.updateSelectedGasPriceType(.custom)
    self.updateGasFeeUI()
  }
  
  func coordinatorDidUpdateAdvancedNonce(_ nonce: String) {
    self.viewModel.advancedNonce = nonce
  }
  
  func coordinatorDidUpdateGasPriceType(_ type: KNSelectedGasPriceType, value: BigInt) {
    self.viewModel.updateSelectedGasPriceType(type)
    self.viewModel.updateGasPrice(value)
    
    self.updateGasFeeUI()
    self.viewModel.resetAdvancedSettings()
  }
  
  func coordinatorDidUpdateApprove(_ item: ApproveMultiSendItem) {
    let cm = self.viewModel.cellModels.first { model in
      return item.1 == model.item.1
    }
    cm?.state = .done
    self.tokensTableView.reloadData()
    
    if self.viewModel.isDoneApprove {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.delegate?.multiSendApproveVieController(self, run: .done)
      }
    }
  }
  
  func coordinatorDidUpdateGasLimit(gas: [(ApproveMultiSendItem, BigInt)]) {
    self.viewModel.gasLimits = gas
    
    DispatchQueue.main.async {
      guard self.isViewLoaded else { return }
      self.updateGasFeeUI()
    }
  }
}

extension MultiSendApproveViewController: BottomPopUpAbstract {
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

extension MultiSendApproveViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.cellModels.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ApproveTokenCell.cellID,
      for: indexPath
    ) as! ApproveTokenCell
    let cm = self.viewModel.cellModels[indexPath.row]
    cell.updateCellModel(cm)
    return cell
  }
}


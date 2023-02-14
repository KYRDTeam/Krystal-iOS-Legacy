//
//  PromoCodeListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import UIKit
import FittedSheets
import Moya

enum PromoCodeListViewEvent {
  case checkCode(code: String)
  case loadUsedCode
  case claim(code: String)
  case openDetail(item: PromoCode)
}

protocol PromoCodeListViewControllerDelegate: class {
  func promoCodeListViewController(_ viewController: PromoCodeListViewController, run event: PromoCodeListViewEvent)
}

class PromoCodeListViewModel {
  
  var searchCodes: [PromoCode] = []
  var usedCodes: [PromoCode] = []
  
  var unusedDataSource: [PromoCodeCellModel] = []
  var usedDataSource: [PromoCodeCellModel] = []
  
  var searchText = ""
  
  func reloadDataSource() {
    unusedDataSource.removeAll()
    usedDataSource.removeAll()
    
    self.unusedDataSource = self.searchCodes.map({ element in
      return PromoCodeCellModel(item: element)
    })
    
    self.usedDataSource = searchText.isEmpty ? self.usedCodes.map({ element in
      return PromoCodeCellModel(item: element)
    }) : []
  }

  var numberOfSection: Int {
    return self.usedDataSource.isEmpty ? 1 : 2
  }
  
  func clearSearchData() {
    unusedDataSource.removeAll()
    self.searchCodes.removeAll()
  }
}

class PromoCodeListViewController: KNBaseViewController {
  
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var promoCodeTableView: UITableView!
  @IBOutlet weak var searchContainerView: UIView!
  @IBOutlet weak var errorLabel: UILabel!
  @IBOutlet weak var scanButton: UIButton!
  
  let viewModel: PromoCodeListViewModel
  var cachedCell: [IndexPath: PromoCodeCell] = [:]
  var keyboardTimer: Timer?
  var statusTimer: Timer?
  var redeemPopup: RedeemPopupViewController?
  var redeemingCode: PromoCode?
  
  weak var delegate: PromoCodeListViewControllerDelegate?
  
  var addressString: String {
    return AppDelegate.session.address.addressString
  }
  
  init(viewModel: PromoCodeListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: PromoCodeListViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupTableView()
    self.setupSearchField()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.updateUIForSearchField(error: "")
    self.reloadData()
  }
  
  func reloadData() {
    self.delegate?.promoCodeListViewController(self, run: .checkCode(code: viewModel.searchText))
    self.delegate?.promoCodeListViewController(self, run: .loadUsedCode)
  }
  
  deinit {
    statusTimer?.invalidate()
    statusTimer = nil
  }
  
  func setupSearchField() {
    searchTextField.text = viewModel.searchText
    searchTextField.setPlaceholder(text: Strings.enterPromotionCode, color: .white.withAlphaComponent(0.5))
  }
  
  func setupTableView() {
    let nib = UINib(nibName: PromoCodeCell.className, bundle: nil)
    self.promoCodeTableView.register(nib, forCellReuseIdentifier: PromoCodeCell.cellID)
    self.promoCodeTableView.rowHeight = UITableView.automaticDimension
    self.promoCodeTableView.estimatedRowHeight = 200
    self.promoCodeTableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: 0.1))
  }
  
  @IBAction func scanWasTapped(_ sender: Any) {
    ScannerModule.start(
      previousScreen: .explore,
      viewController: self,
      acceptedResultTypes: [.promotionCode],
      scanModes: [.qr]
    ) { [weak self] text, type in
        guard let self = self else { return }
        switch type {
        case .promotionCode:
          guard let code = ScannerUtils.getPromotionCode(text: text) else { return }
          self.searchTextField.text = code
          self.viewModel.searchText = code
          self.delegate?.promoCodeListViewController(self, run: .checkCode(code: code))
        default:
          return
        }
      }
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  private func updateUIForSearchField(error: String) {
    if error.isEmpty {
      self.searchContainerView.rounded(radius: 16)
      self.searchTextField.textColor = UIColor(named: "textWhiteColor")
      self.errorLabel.isHidden = true
      self.scanButton.isHidden = false
      self.errorLabel.text = ""
    } else {
      self.searchContainerView.rounded(color: UIColor(named: "textRedColor")!, width: 1, radius: 16)
      self.searchTextField.textColor = UIColor(named: "textRedColor")
      self.errorLabel.isHidden = false
      self.errorLabel.text = error
      self.scanButton.isHidden = true
    }
  }
  
  func coordinatorDidUpdateSearchPromoCodeItems(_ codes: [PromoCode], searchText: String) {
    guard self.viewModel.searchText == searchText else { return }
    self.viewModel.searchCodes = codes
    self.viewModel.reloadDataSource()
    guard self.isViewLoaded else { return }
    self.promoCodeTableView.reloadData()
    if codes.isEmpty && !searchText.isEmpty {
      self.updateUIForSearchField(error: Strings.invalidPromotionCode)
    } else {
      self.updateUIForSearchField(error: "")
    }
  }

  func coordinatorDidUpdateUsedPromoCodeItems(_ codes: [PromoCode]) {
    self.viewModel.usedCodes = codes
    self.viewModel.reloadDataSource()
    guard self.isViewLoaded else { return }
    self.promoCodeTableView.reloadData()
  }
  
  func coordinatorDidClaimSuccessCode() {
    self.viewModel.clearSearchData()
    self.searchTextField.text = ""
    self.delegate?.promoCodeListViewController(self, run: .loadUsedCode)
  }
  
  func coordinatorDidReceiveClaimError(_ error: String) {
    self.updateUIForSearchField(error: error)
  }
}

extension PromoCodeListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberOfSection
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return self.viewModel.unusedDataSource.count
    } else {
      return self.viewModel.usedDataSource.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: PromoCodeCell.cellID,
      for: indexPath
    ) as! PromoCodeCell
    
    if indexPath.section == 0 {
      let cm = self.viewModel.unusedDataSource[indexPath.row]
      cell.updateCellModel(cm)
    } else {
      let cm = self.viewModel.usedDataSource[indexPath.row]
      cell.updateCellModel(cm)
    }
    cell.delegate = self
    self.cachedCell[indexPath] = cell
    return cell
  }
}

extension PromoCodeListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let cell = self.cachedCell[indexPath] {
      let value = self.calculateHeightForConfiguredSizingCell(cell: cell)
      return value
    }

    return UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section == 1 else { return UIView(frame: CGRect.zero) }
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 24))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 31, y: 0, width: 200, height: 24))
    titleLabel.center.y = view.center.y
    titleLabel.text = "Promo Code Used"
    titleLabel.font = UIFont.Kyber.bold(with: 16)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    } else {
      return 32
    }
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if indexPath.section == 0 {
      let cm = self.viewModel.unusedDataSource[indexPath.row]
      self.delegate?.promoCodeListViewController(self, run: .openDetail(item: cm.item))
    } else {
      let cm = self.viewModel.usedDataSource[indexPath.row]
      self.delegate?.promoCodeListViewController(self, run: .openDetail(item: cm.item))
    }
  }
  
  func calculateHeightForConfiguredSizingCell(cell: PromoCodeCell) -> CGFloat {
    cell.setNeedsLayout()
    cell.layoutIfNeeded()
    let height = cell.containerView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height + 20
    return height
  }
}

extension PromoCodeListViewController: UITextFieldDelegate {
  
  func onSearchTextUpdated(text: String) {
    viewModel.searchText = text
    if text.isEmpty {
      self.viewModel.clearSearchData()
      self.promoCodeTableView.reloadData()
      self.updateUIForSearchField(error: "")
      self.delegate?.promoCodeListViewController(self, run: .loadUsedCode)
    } else {
      self.delegate?.promoCodeListViewController(self, run: .checkCode(code: text))
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    onSearchTextUpdated(text: textField.text ?? "")
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    onSearchTextUpdated(text: textField.text ?? "")
  }
  
  func textFieldShouldClear(_ textField: UITextField) -> Bool {
    onSearchTextUpdated(text: "")
    return true
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    self.updateUIForSearchField(error: "")
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    self.keyboardTimer?.invalidate()
    self.keyboardTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(PromoCodeListViewController.keyboardPauseTyping),
            userInfo: ["textField": textField],
            repeats: false)
    return true
  }
  
  @objc func keyboardPauseTyping(timer: Timer) {
    self.checkRequestCode()
  }
  
  fileprivate func checkRequestCode() {
    guard let text = self.searchTextField.text, text != self.viewModel.searchText else {
      return
    }
    onSearchTextUpdated(text: text)
  }
}

extension PromoCodeListViewController: PromoCodeCellDelegate {
  func promoCodeCell(_ cell: PromoCodeCell, claim code: PromoCode) {
    Tracker.track(event: .promotionClaim)
    
    redeemingCode = code
    requestClaim(code: code.code)
    openRedeemPopup(code: code)
  }
}

extension PromoCodeListViewController: RedeemPopupViewControllerDelegate {
  
  func onOpenTxHash(popup: RedeemPopupViewController, txHash: String, chainID: Int) {
    popup.dismiss(animated: true) { [weak self] in
      self?.openTxHash(txHash: txHash, chainID: chainID)
    }
  }
  
  func openRedeemPopup(code: PromoCode) {
    let popup = RedeemPopupViewController.instantiateFromNib()
    popup.promoCode = code
    popup.delegate = self
    
    var options = SheetOptions()
    options.pullBarHeight = 0
    let sheet = SheetViewController(controller: popup, sizes: [.intrinsic], options: options)
    sheet.allowPullingPastMinHeight = false
    sheet.didDismiss = { [weak self] _ in
      self?.onRedeemPopupClose()
    }
    redeemPopup = popup
    present(sheet, animated: true)
  }
  
  func onRedeemPopupClose() {
    redeemPopup = nil
    reloadData()
  }
  
  @objc func checkstatus() {
    guard let code = redeemingCode?.code else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    guard let codePrefix = code.split(separator: "-").first else { return }
    provider.requestWithFilter(.getPromotions(code: String(codePrefix), address: addressString)) { [weak self] result in
      switch result {
      case .success(let responseData):
        let promotions = try? JSONDecoder().decode(PromotionResponse.self, from: responseData.data)
        if let code = promotions?.codes.first(where: { $0.code == code }) {
          self?.redeemPopup?.updateTxHash(hash: code.claimTx)
          switch code.txnStatus {
          case "success":
            self?.requestClaimSuccess()
          default:
            return
          }
        }
      case .failure:
        return
      }
    }
  }
  
  func scheduleCheckStatus() {
    statusTimer?.invalidate()
    statusTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(checkstatus), userInfo: nil, repeats: true)
  }
  
  func requestClaim(code: String) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(successCodes: 200...400, .claimPromotion(code: code, address: addressString)) { [weak self] result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let _ = try decoder.decode(ClaimResponse.self, from: resp.data)
          self?.scheduleCheckStatus()
        } catch {
          do {
            let data = try decoder.decode(ClaimErrorResponse.self, from: resp.data)
            self?.requestClaimFailed(message: data.error.capitalized)
          } catch {
            self?.requestClaimFailed(message: "Can not decode data")
          }
        }
      case .failure(let error):
        self?.requestClaimFailed(message: error.localizedDescription)
      }
    }
  }
  
  func requestClaimFailed(message: String) {
    if let redeemPopup = self.redeemPopup {
      redeemPopup.status = .failure(message: message)
    } else {
      showTopBannerView(with: Strings.redeemFailed, message: message)
    }
  }
  
  func requestClaimSuccess() {
    if let redeemPopup = self.redeemPopup {
      redeemPopup.status = .success
    } else {
      showTopBannerView(message: Strings.redeemSuccessMessage)
    }
    redeemingCode = nil
    reloadData()
  }
  
}

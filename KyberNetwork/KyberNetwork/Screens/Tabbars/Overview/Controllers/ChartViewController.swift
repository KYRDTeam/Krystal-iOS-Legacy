//
//  ChartViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/24/21.
//

import UIKit
import SwiftChart
import BigInt
import MBProgressHUD

class ChartViewModel {
  var dataSource: [(x: Double, y: Double)] = []
  var poolData: [TokenPoolDetail] = []
  var xLabels: [Double] = []
  let token: Token
  var periodType: ChartPeriodType = .oneDay
  var detailInfo: TokenDetailInfo?
  var chartData: [[Double]]?
  var chartOriginTimeStamp: Double = 0

  var currency: String
  let currencyMode: CurrencyMode
  var isFaved: Bool
  var chainId = KNGeneralProvider.shared.currentChain.getChainId()
  
  @UserDefault(key: Constants.hideBalanceKey, defaultValue: false)
  var hideBalanceStatus: Bool
  
  var isExpandingPoolTable: Bool = false
  let lendingTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self)

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()
  
  var selectedPoolDetail: TokenPoolDetail?

  init(token: Token, currencyMode: CurrencyMode) {
    self.token = token
    self.currencyMode = currencyMode
    self.currency = currencyMode.toString()
    self.isFaved = KNSupportedTokenStorage.shared.getFavedStatusWithAddress(token.address)
  }
  
  func updateChartData(_ data: [[Double]]) {
    guard !data.isEmpty else { return }
    self.chartData = data
    let originTimeStamp = data[0][0]
    self.chartOriginTimeStamp = originTimeStamp
    self.dataSource = data.map { (item) -> (x: Double, y: Double) in
      return (x: item[0] - originTimeStamp, y: item[1])
    }
    if let lastTimeStamp = data.last?[0] {
      let interval = lastTimeStamp - originTimeStamp
      let divide = interval / 7
      self.xLabels = [0, divide, divide * 2, divide * 3, divide * 4, divide * 5, divide * 6]
    }
  }
  
  var series: ChartSeries {
    let series = ChartSeries(data: self.dataSource)
    series.area = true
    series.colors = (above: self.displayDiffColor!, below: UIColor(named: "mainViewBgColor")!, 0)
    return series
  }
  
  var displayPrice: String {
    return self.numberFormatter.string(from: NSNumber(value: self.detailInfo?.markets[self.currency]?.price ?? 0))?.displayRate(meaningNumber: 2) ?? "0"
  }

  var display24hVol: String {
    let volume24H = self.detailInfo?.markets[self.currency]?.volume24H ?? 0
    return self.currencyMode.symbol() + "\(self.formatPoints(volume24H))" + self.currencyMode.suffixSymbol()
  }

  var diffPercent: Double {
    switch self.periodType {
    case .oneDay:
      return self.detailInfo?.markets[self.currency]?.priceChange24HPercentage ?? 0
    case .sevenDay:
      return self.detailInfo?.markets[self.currency]?.priceChange7DPercentage ?? 0
    case .oneMonth:
      return self.detailInfo?.markets[self.currency]?.priceChange30DPercentage ?? 0
    case .threeMonth:
      return self.detailInfo?.markets[self.currency]?.priceChange200DPercentage ?? 0
    case .oneYear:
      return self.detailInfo?.markets[self.currency]?.priceChange1YPercentage ?? 0
    }
  }

  var displayDiffPercent: String {
    return String(format: "%.2f", self.diffPercent) + "%"
  }
  
  var displayDiffColor: UIColor? {
    return self.diffPercent > 0 ? UIColor(named: "buttonBackgroundColor") : UIColor(named: "textRedColor")
  }
  
  var diffImage: UIImage {
    return self.diffPercent > 0 ? UIImage(named: "icon-price-up")! : UIImage(named: "icon-price-down")!
  }
  
  var diplayBalance: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address), let balanceBigInt = BigInt(balance.balance) else { return "---" }
    let balanceString = balanceBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 4))
    let shortTypeBalance = String.formatBigNumberCurrency(balanceString.doubleValue)
    return shortTypeBalance + " \(self.token.symbol.uppercased())"
  }
  
  var displayUSDBalance: String {
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address),
          let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address),
          let balanceBigInt = BigInt(balance.balance)
    else {
      return "---"
    }
    var price = self.token.getTokenLastPrice(self.currencyMode)
    
    let rateBigInt = BigInt(price * pow(10.0, 18.0))
    let valueBigInt = balanceBigInt * rateBigInt / BigInt(10).power(18)
    return self.currencyMode.symbol() + valueBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: self.currencyMode.decimalNumber()) + self.currencyMode.suffixSymbol()
  }

  var marketCap: Double {
    return self.detailInfo?.markets[self.currency]?.marketCap ?? 0
  }
  
  var displayMarketCap: String {
    return self.currencyMode.symbol() + "\(self.formatPoints(self.marketCap))" + self.currencyMode.suffixSymbol()
  }
  
  var displayAllTimeHigh: String {
    let ath = self.detailInfo?.markets[self.currency]?.ath ?? 0
    return self.currencyMode.symbol() + "\(self.formatPoints(ath))" + self.currencyMode.suffixSymbol()
  }

  var displayAllTimeLow: String {
    let atl = self.detailInfo?.markets[self.currency]?.atl ?? 0
    return self.currencyMode.symbol() + "\(self.formatPoints(atl))" + self.currencyMode.suffixSymbol()
  }

  var displayDescription: String {
    return self.detailInfo?.resultDescription ?? ""
  }

  var displayDescriptionAttribution: NSAttributedString? {
    guard let attributedString = try? NSAttributedString(
      data: self.displayDescription.data(using: .utf8) ?? Data(),
      options: [.documentType: NSAttributedString.DocumentType.html],
      documentAttributes: nil
    ) else {
      return nil
    }
    let string = NSMutableAttributedString(attributedString: attributedString)
    string.addAttributes([
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor") as Any,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 14),
    ], range: NSRange(location: 0, length: attributedString.length)
    )
    return string
  }

  var headerTitle: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let titleAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.bold(with: 20),
      NSAttributedString.Key.kern: 0.0,
    ]
    let subTitleAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!,
      NSAttributedString.Key.font: UIFont.Kyber.regular(with: 18),
      NSAttributedString.Key.kern: 0.0,
    ]
    var titleString = ""
    if let detailInfo = self.detailInfo {
      titleString = "\(detailInfo.symbol.uppercased())"
    } else {
      titleString = "\(self.token.symbol.uppercased())"
    }
    var subTitleString = ""
    if let detailInfo = self.detailInfo {
      subTitleString = "\(detailInfo.name.uppercased())"
    } else {
      subTitleString = "\(self.token.name.uppercased())"
    }
    attributedString.append(NSAttributedString(string: "\(titleString) ", attributes: titleAttributes))
    attributedString.append(NSAttributedString(string: "\(subTitleString)", attributes: subTitleAttributes))
    return attributedString
  }

  var tagImage: UIImage? {
    guard let tag = self.detailInfo?.tag else { return nil }
     if tag == VERIFIED_TAG {
       return UIImage(named: "blueTick_icon")
     } else if tag == PROMOTION_TAG {
       return UIImage(named: "green-checked-tag-icon")
     } else if tag == SCAM_TAG {
       return UIImage(named: "warning-tag-icon")
     } else if tag == UNVERIFIED_TAG {
       return nil
     }
     return nil
   }
  
  var tagLabel: String {
    guard let tag = self.detailInfo?.tag else { return "" }
     if tag == VERIFIED_TAG {
       return "Verified Token".toBeLocalised()
     } else if tag == PROMOTION_TAG {
       return "New Token".toBeLocalised()
     } else if tag == SCAM_TAG {
       return "Untrusted Token".toBeLocalised()
     } else if tag == UNVERIFIED_TAG {
       return ""
     }
     return ""
  }

  func formatPoints(_ number: Double) -> String {
    return String.formatBigNumberCurrency(number).displayRate()
  }
  
  func displayChartDetaiInfoAt(index: Int) -> NSAttributedString {
    guard let priceItem = self.chartData?[index],
    let price = priceItem.last,
    let timestamp = priceItem.first
    else {
      return NSAttributedString()
    }
    let date = Date(timeIntervalSince1970: timestamp * 0.001)
    let dateFormater = DateFormatterUtil.shared.chartViewDateFormatter
    let dateString = dateFormater.string(from: date)
    let normalAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.latoRegular(with: 10),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let boldAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.Kyber.latoBold(with: 10),
      NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWWhiteTextColor,
    ]
    let priceBigInt = BigInt(price * pow(10.0, 18.0))

    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: dateString + " ", attributes: boldAttributes))
    attributedText.append(NSAttributedString(string: "  Price" + ": ", attributes: boldAttributes))

    let valueString = priceBigInt.string(decimals: 18, minFractionDigits: 18, maxFractionDigits: 18).displayRate(meaningNumber: 2)
    let displayString = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol()
    
    attributedText.append(NSAttributedString(string: displayString, attributes: normalAttributes))

    return attributedText
  }
  
  var displayFavIcon: UIImage? {
    return self.isFaved ? UIImage(named: "fav_star_icon") : UIImage(named: "unFav_star_icon")
  }
  
  var canEarn: Bool {
    if let earnTokens = self.lendingTokens {
      let addresses = earnTokens.map { $0.address.lowercased() }
      return addresses.contains(self.token.address.lowercased())
    } else {
      return false
    }
  }
  
  var displayPoolName: String {
    guard let selectedPoolDetail = selectedPoolDetail else {
      return ""
    }
    if selectedPoolDetail.token1.address.lowercased() == baseTokenAddress.lowercased() {
      return "\(selectedPoolDetail.token1.symbol)/\(selectedPoolDetail.token0.symbol)"
    } else {
      return "\(selectedPoolDetail.token0.symbol)/\(selectedPoolDetail.token1.symbol)"
    }
    
  }
  
  var baseTokenAddress: String {
    if token.isQuoteToken {
      let wsymbol = "W" + self.token.symbol
      if let wtoken = KNSupportedTokenStorage.shared.supportedToken.first { $0.symbol == wsymbol } {
        return wtoken.address
      }
    }
    return token.address
  }
}

enum ChartViewEvent {
  case getChartData(address: String, from: Int, to: Int, currency: String)
  case getTokenDetailInfo(address: String)
  case transfer(token: Token)
  case swap(token: Token)
  case invest(token: Token)
  case openEtherscan(address: String)
  case openWebsite(url: String)
  case openTwitter(name: String)
  case getPoolList(address: String, chainId: Int)
  case selectPool(source: String, quote: String)
}

enum ChartPeriodType: Int {
  case oneDay = 1
  case sevenDay
  case oneMonth
  case threeMonth
  case oneYear
  
  func getFromTimeStamp() -> Int {
    let current = NSDate().timeIntervalSince1970
    var interval = 0
    switch self {
    case .oneDay:
      interval = 24 * 60 * 60
    case .sevenDay:
      interval = 7 * 24 * 60 * 60
    case .oneMonth:
      interval = 30 * 24 * 60 * 60
    case .threeMonth:
      interval = 3 * 30 * 24 * 60 * 60
    case .oneYear:
      interval = 12 * 30 * 24 * 60 * 60
    }
    return Int(current) - interval
  }
}

protocol ChartViewControllerDelegate: class {
  func chartViewController(_ controller: ChartViewController, run event: ChartViewEvent)
}

class ChartViewController: KNBaseViewController {
  @IBOutlet weak var containScrollView: UIScrollView!
  @IBOutlet weak var chartContainerView: UIView!
  @IBOutlet var periodChartSelectButtons: [UIButton]!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var priceDiffPercentageLabel: UILabel!
  @IBOutlet weak var priceDiffImageView: UIImageView!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var ethBalanceLabel: UILabel!
  @IBOutlet weak var usdBalanceLabel: UILabel!
  @IBOutlet weak var marketCapLabel: UILabel!
  @IBOutlet weak var atlLabel: UILabel!
  @IBOutlet weak var athLabel: UILabel!
  @IBOutlet weak var titleView: UILabel!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!
  @IBOutlet weak var investButton: UIButton!
  @IBOutlet weak var descriptionTextView: GrowingTextView!
  @IBOutlet weak var chartDetailLabel: UILabel!
  @IBOutlet weak var noDataLabel: UILabel!
  @IBOutlet weak var favButton: UIButton!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var tagLabelWidth: NSLayoutConstraint!
  @IBOutlet weak var addressToSuperViewLeading: NSLayoutConstraint!
  @IBOutlet weak var addressToSuperViewTrailing: NSLayoutConstraint!
  @IBOutlet weak var addressLeading: NSLayoutConstraint!
  @IBOutlet weak var tagView: UIView!
  @IBOutlet weak var chainView: UIView!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainAddressLabel: UILabel!
  @IBOutlet weak var infoSegment: SegmentedControl!
  @IBOutlet weak var aboutTitleLabel: UILabel!
  @IBOutlet weak var poolTableView: UITableView!
  @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
  @IBOutlet weak var poolViewTrailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var poolView: UIView!
  @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var lineChartView: UIView!
  @IBOutlet weak var showAllPoolButton: UIButton!
  @IBOutlet weak var poolNameContainerView: UIView!
  @IBOutlet weak var poolNameLabel: UILabel!
  @IBOutlet weak var chartDurationTopSpacing: NSLayoutConstraint!
  @IBOutlet weak var tradingView: TradingView!
  @IBOutlet weak var tokenChartView: Chart!
  @IBOutlet weak var chartTopToPoolButtonConstraint: NSLayoutConstraint!
  @IBOutlet weak var chartTopToTimeConstraint: NSLayoutConstraint!
  @IBOutlet weak var intervalStackview: UIStackView!
  @IBOutlet weak var chartHeight: NSLayoutConstraint!
  
  weak var delegate: ChartViewControllerDelegate?
  let viewModel: ChartViewModel
  fileprivate var tokenPoolTimer: Timer?
  
  var isSelectingLineChart: Bool = true {
    didSet {
      self.reloadCharts()
    }
  }
  
  init(viewModel: ChartViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ChartViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupConstraints()
    self.setupPoolInfoView()
    self.setupInfoSegment()
    self.setupTableView()
    self.setupTitle()
    self.setupButtons()
    self.setupChartViews()
    self.loadTokenChartData()
    self.reloadCharts()
  }
  
  func setupTitle() {
    self.titleView.attributedText = self.viewModel.headerTitle
  }
  
  func setupPoolInfoView() {
    self.updateUIPoolName(hidden: true)
  }
  
  func setupInfoSegment() {
    self.infoSegment.highlightSelectedSegment()
    self.infoSegment.frame = CGRect(x: self.infoSegment.frame.minX, y: self.infoSegment.frame.minY, width: self.infoSegment.frame.width, height: 40)
    self.infoSegment.selectedSegmentIndex = 0
  }
  
  func setupButtons() {
    self.updateUIPeriodSelectButtons()
    self.titleView.attributedText = self.viewModel.headerTitle
    self.transferButton.rounded(radius: 16)
    self.swapButton.rounded(radius: 16)
    self.investButton.rounded(radius: 16)
    self.favButton.setImage(self.viewModel.displayFavIcon, for: .normal)
    self.favButton.isHidden = self.viewModel.chainId != KNGeneralProvider.shared.currentChain.getChainId()
    periodChartSelectButtons.forEach { (button) in
      button.rounded(radius: 7)
    }
    if !self.viewModel.canEarn {
      self.investButton.removeFromSuperview()
      self.swapButton.rightAnchor.constraint(equalTo: self.swapButton.superview!.rightAnchor, constant: -26).isActive = true
    }
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(copyTokenAddress))
    self.chainAddressLabel.isUserInteractionEnabled = true
    self.chainAddressLabel.addGestureRecognizer(tapGesture)
  }

  func setupTableView() {
    self.poolTableView.registerCellNib(TokenPoolCell.self)
  }
  
  func setupChartViews() {
    tokenChartView.showYLabelsAndGrid = false
    tokenChartView.labelColor = UIColor.Kyber.SWPlaceHolder
    tokenChartView.labelFont = UIFont.Kyber.latoRegular(with: 10)
    tokenChartView.axesColor = .clear
    tokenChartView.gridColor = .clear
    tokenChartView.backgroundColor = .clear
    tokenChartView.delegate = self
  }
  
  func reloadCharts() {
    noDataLabel.isHidden = true
    lineChartView.isHidden = !isSelectingLineChart
    chartDetailLabel.isHidden = !isSelectingLineChart
    tradingView.isHidden = isSelectingLineChart
    intervalStackview.isHidden = !isSelectingLineChart
    chartTopToPoolButtonConstraint.isActive = !isSelectingLineChart
    chartTopToTimeConstraint.isActive = isSelectingLineChart
    
    UIView.animate(withDuration: 1.0) {
      self.chartHeight.constant = self.isSelectingLineChart ? 220 : 312
    }
  }
  
  @objc func copyTokenAddress() {
    UIPasteboard.general.string = self.viewModel.token.address
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
  }

  func setupConstraints() {
    topBarHeight?.constant = UIScreen.statusBarHeight + 36 * 2 + 24
    self.textViewLeadingConstraint.constant = UIScreen.main.bounds.size.width + 20
  }
  
  func updateUIPoolName(hidden: Bool) {
    self.poolNameContainerView.isHidden = hidden
    self.poolNameLabel.text = self.viewModel.displayPoolName
    self.chartDurationTopSpacing.constant = hidden ? 20 : 52
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.getPoolList()
    self.loadTokenDetailInfo()
    self.updateUIChartInfo()
    self.updateUITokenInfo()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.tokenPoolTimer?.invalidate()
    self.tokenPoolTimer = nil
  }
  
  func showPoolView() {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.tableViewHeight.priority = .required
      self.poolViewTrailingConstraint.constant = 0
      self.textViewLeadingConstraint.constant = UIScreen.main.bounds.size.width + 20
      self.view.layoutIfNeeded()
    }
  }
  
  func hidePoolView(_ animate: Bool = true) {
    if animate {
      UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
        self.tableViewHeight.priority = .fittingSizeLevel
        self.poolViewTrailingConstraint.constant = UIScreen.main.bounds.size.width
        self.textViewLeadingConstraint.constant = 20
        self.view.layoutIfNeeded()
      }
    } else {
      self.tableViewHeight.priority = .fittingSizeLevel
      self.poolViewTrailingConstraint.constant = UIScreen.main.bounds.size.width
      self.textViewLeadingConstraint.constant = 20
      self.view.layoutIfNeeded()
    }
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    self.infoSegment.underlinePosition()
    if sender.selectedSegmentIndex == 1 {
      self.hidePoolView()
    } else {
      self.showPoolView()
    }
  }

  @IBAction func changeChartPeriodButtonTapped(_ sender: UIButton) {
    guard let type = ChartPeriodType(rawValue: sender.tag), type != self.viewModel.periodType else {
      return
    }
    self.viewModel.periodType = type
    self.updateUIPeriodSelectButtons()
    self.updateUITokenInfo()
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func transferButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .transfer(token: self.viewModel.token))
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .swap(token: self.viewModel.token))
  }
  
  @IBAction func investButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .invest(token: self.viewModel.token))
  }
  
  @IBAction func etherscanButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openEtherscan(address: self.viewModel.token.address))
  }
  
  @IBAction func websiteButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openWebsite(url: self.viewModel.detailInfo?.links.homepage ?? ""))
  }
  
  @IBAction func twitterButtonTapped(_ sender: UIButton) {
    self.delegate?.chartViewController(self, run: .openTwitter(name: self.viewModel.detailInfo?.links.twitterScreenName ?? ""))
  }
  
  @IBAction func favButtonTapped(_ sender: UIButton) {
    viewModel.isFaved = !viewModel.isFaved
    KNSupportedTokenStorage.shared.setFavedStatusWithAddress(viewModel.token.address, status: viewModel.isFaved)
    self.favButton.setImage(self.viewModel.displayFavIcon, for: .normal)
  }
  
  @IBAction func showAllPoolButtonTapped(_ sender: Any) {
    self.viewModel.isExpandingPoolTable = !self.viewModel.isExpandingPoolTable
    self.showAllPoolButton.setTitle(self.viewModel.isExpandingPoolTable ? Strings.showLess : Strings.showMore, for: .normal)
    self.updatePoolTableHeight()
  }
  
  @IBAction func closeCandleChartButtonTapped(_ sender: UIButton) {
    self.isSelectingLineChart = true
    self.viewModel.selectedPoolDetail = nil
    self.updateUIPoolName(hidden: true)
    self.poolTableView.reloadData()
  }

  fileprivate func updateUIChartInfo() {
    self.updateUIPeriodSelectButtons()
  }

  fileprivate func updateUITokenInfo() {
    self.titleView.attributedText = self.viewModel.headerTitle
    self.atlLabel.text = self.viewModel.displayAllTimeLow
    self.athLabel.text = self.viewModel.displayAllTimeHigh
    self.descriptionTextView.attributedText = self.viewModel.displayDescriptionAttribution
    self.priceLabel.text = self.viewModel.displayPrice
    self.volumeLabel.text = self.viewModel.display24hVol
    self.ethBalanceLabel.text = self.viewModel.diplayBalance
    self.usdBalanceLabel.text = self.viewModel.displayUSDBalance
    self.marketCapLabel.text = self.viewModel.displayMarketCap
    self.priceDiffPercentageLabel.text = self.viewModel.displayDiffPercent
    self.priceDiffPercentageLabel.textColor = self.viewModel.displayDiffColor
    self.priceDiffImageView.image = self.viewModel.diffImage
    self.swapButton.backgroundColor = self.viewModel.displayDiffColor
    self.transferButton.backgroundColor = self.viewModel.displayDiffColor
    if self.viewModel.canEarn {
      self.investButton.backgroundColor = self.viewModel.displayDiffColor
    }
    if let image = self.viewModel.tagImage {
      self.tagImageView.image = image
      self.tagLabel.text = self.viewModel.tagLabel
      self.tagLabelWidth.constant = self.viewModel.tagLabel.width(withConstrainedHeight: 28, font: UIFont.Kyber.regular(with: 12))
      self.addressToSuperViewLeading.isActive = false
      self.addressToSuperViewTrailing.constant = 20
      self.addressLeading.isActive = true
      self.tagView.isHidden = false
    } else {
      self.tagView.isHidden = true
      self.addressToSuperViewLeading.isActive = true
      let addressViewWidth = self.viewModel.token.address.width(withConstrainedHeight: 28, font: UIFont.Kyber.regular(with: 12)) + 43
      let padding = (UIScreen.main.bounds.size.width - addressViewWidth) / 2
      self.addressToSuperViewLeading.constant = CGFloat(padding)
      self.addressToSuperViewTrailing.constant = CGFloat(padding)
      self.addressLeading.isActive = false
    }
    
    if let chain = ChainType.make(chainID: self.viewModel.chainId) {
      self.chainIcon.image = chain.chainIcon()
    } else {
      self.chainIcon.image = KNGeneralProvider.shared.chainIconImage
    }

    self.chainAddressLabel.text = self.viewModel.token.address
  }
  
  func loadTokenChartData() {
    let current = NSDate().timeIntervalSince1970
    self.delegate?.chartViewController(self, run: .getChartData(address: self.viewModel.token.address, from: self.viewModel.periodType.getFromTimeStamp(), to: Int(current), currency: self.viewModel.currency))
  }

  fileprivate func loadTokenDetailInfo() {
    self.delegate?.chartViewController(self, run: .getTokenDetailInfo(address: self.viewModel.token.address))
  }
  
  fileprivate func getPoolList() {
    var address = self.viewModel.token.address
    if self.viewModel.token.isQuoteToken {
      // incase current token is native token, find wrap token instead
      let wsymbol = "W" + self.viewModel.token.symbol
      if let wtoken = KNSupportedTokenStorage.shared.supportedToken.first { $0.symbol == wsymbol } {
        address = wtoken.address
      }
    }
    self.delegate?.chartViewController(self, run: .getPoolList(address: address, chainId: self.viewModel.chainId ))
    self.tokenPoolTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds15,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.delegate?.chartViewController(self, run: .getPoolList(address: address, chainId: self.viewModel.chainId ))
      }
    )
    
  }

  fileprivate func updateUIPeriodSelectButtons() {
    self.periodChartSelectButtons.forEach { (button) in
      if button.tag == self.viewModel.periodType.rawValue {
        button.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
        button.backgroundColor = self.viewModel.displayDiffColor
      } else {
        button.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
        button.backgroundColor = .clear
      }
    }
  }
  
  func updatePoolTableHeight() {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      if self.viewModel.isExpandingPoolTable {
        self.tableViewHeight.constant = CGFloat(self.viewModel.poolData.count * 92)
      } else {
        self.tableViewHeight.constant = CGFloat(460)
      }
      self.view.layoutIfNeeded()
    }
  }
  
  func coordinatorDidUpdatePoolData(poolData: [TokenPoolDetail]) {
    if poolData.isEmpty {
      self.infoSegment.isHidden = true
      self.aboutTitleLabel.isHidden = false
      self.hidePoolView(false)
      return
    }
    self.infoSegment.isHidden = false
    self.aboutTitleLabel.isHidden = true
    self.viewModel.poolData = poolData
    self.showAllPoolButton.isHidden = poolData.count <= 5
    self.poolTableView.reloadData()
    self.updatePoolTableHeight()
  }

  func coordinatorDidUpdateChartData(_ data: [[Double]]) {
    self.noDataLabel.isHidden = !data.isEmpty
    self.viewModel.updateChartData(data)
    self.tokenChartView.removeAllSeries()
    self.tokenChartView.add(self.viewModel.series)
    self.tokenChartView.xLabels = self.viewModel.xLabels
    self.updateUIChartInfo()
    self.tokenChartView.xLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
      let timestamp = labelValue + self.viewModel.chartOriginTimeStamp
      let date = Date(timeIntervalSince1970: timestamp * 0.001)
      let calendar = Calendar.current
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "EE"
      let hour = calendar.component(.hour, from: date)
      let minutes = calendar.component(.minute, from: date)
      let day = calendar.component(.day, from: date)
      let month = calendar.component(.month, from: date)
      let year = calendar.component(.year, from: date)
      switch self.viewModel.periodType {
      case .oneDay:
        return String(format: "%02d:%02d", hour, minutes)
      case .sevenDay:
        return "\(dateFormatter.string(from: date)) \(hour)"
      case .oneMonth, .threeMonth:
        return "\(day)/\(month)"
      case .oneYear:
        return "\(month)/\(year)"
      }
    }
  }

  func coordinatorFailUpdateApi(_ error: Error) {
    self.showErrorTopBannerMessage(with: "", message: error.localizedDescription)
  }

  func coordinatorDidUpdateTokenDetailInfo(_ detailInfo: TokenDetailInfo?) {
    guard let detailInfo = detailInfo else {
      self.navigationController?.popToRootViewController(animated: true)
      let errorVC = ErrorViewController()
      errorVC.modalPresentationStyle = .fullScreen
      self.present(errorVC, animated: false)
      return
    }
    self.viewModel.detailInfo = detailInfo
    self.updateUITokenInfo()
    self.updateUIChartInfo()
  }
  
  func reloadPoolTradingView(pool: TokenPoolDetail) {
    guard let chain = ChainType.allCases.first(where: { chain in
      chain.getChainId() == pool.chainId
    }) else { return }
    let source = pool.token0.address
    let quote = pool.token1.address
    let request = ChartLoadRequestBuilder()
      .symbol("\(pool.token0.symbol)/\(pool.token1.symbol)")
      .chain(chain.customRPC().apiChainPath)
      .baseAddress(source)
      .quoteAddress(quote)
      .period(.h1)
      .chartType(.candles)
      .build()
    
    tradingView.load(request: request)
  }
  
  func onSelectPool(pool: TokenPoolDetail) {
    if self.viewModel.selectedPoolDetail?.address == pool.address {
      return
    }
    self.viewModel.selectedPoolDetail = pool
    self.updateUIPoolName(hidden: false)
    self.poolTableView.reloadData()
    self.containScrollView.setContentOffset(CGPoint.zero, animated: true)
    self.reloadPoolTradingView(pool: pool)
  }
}

extension ChartViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.poolData.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(TokenPoolCell.self, indexPath: indexPath)!
    let poolData = self.viewModel.poolData[indexPath.row]
    let isSelecting = poolData.address == viewModel.selectedPoolDetail?.address
    cell.updateUI(isSelecting: isSelecting, poolDetail: poolData, baseTokenAddress: viewModel.baseTokenAddress, currencyMode: .usd)
    return cell
  }
}

extension ChartViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.isSelectingLineChart = false
    let poolData = self.viewModel.poolData[indexPath.row]
    onSelectPool(pool: poolData)
  }
  
}

extension ChartViewController: ChartDelegate {
  func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
    guard let index = indexes.first, let unwrappedIdx = index else {
      return
    }
    self.chartDetailLabel.attributedText = self.viewModel.displayChartDetaiInfoAt(index: unwrappedIdx)
  }
  
  func didFinishTouchingChart(_ chart: Chart) {
    
  }
  
  func didEndTouchingChart(_ chart: Chart) {
    
  }
}

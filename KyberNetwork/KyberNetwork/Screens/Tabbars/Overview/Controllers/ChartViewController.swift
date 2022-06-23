//
//  ChartViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/24/21.
//

import UIKit
import SwiftChart
import BigInt
import LightweightCharts

class ChartViewModel {
  var poolData: [TokenPoolDetail] = []
  var xLabels: [Double] = []
  let token: Token
  var periodType: ChartPeriodType = .oneDay
  var detailInfo: TokenDetailInfo?
  var chartData: [[Double]]?

  var currency: String
  let currencyMode: CurrencyMode
  var isFaved: Bool
  var chainId = KNGeneralProvider.shared.currentChain.getChainId()
  var hideBalanceStatus: Bool = UserDefaults.standard.bool(forKey: Constants.hideBalanceKey) {
    didSet {
      UserDefaults.standard.set(self.hideBalanceStatus, forKey: Constants.hideBalanceKey)
    }
  }
  var isExpandingPoolTable: Bool = false
  let lendingTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self)

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()
  
  var tradingViewCandleData: [TradingViewData] = []
  var candleSeries: CandlestickSeries!
  
  var lineSeries: LineSeries!
  
  var tradingViewLineData: [SingleValueData] = []
  
  var isLineChartMode: Bool = true
  var selectedPoolDetail: TokenPoolDetail?
  var selectedPool: (String, String) {
    return (selectedPoolDetail?.token0.address ?? "", selectedPoolDetail?.token1.address ?? "")
  }

  init(token: Token, currencyMode: CurrencyMode) {
    self.token = token
    self.currencyMode = currencyMode
    self.currency = currencyMode.toString()
    self.isFaved = KNSupportedTokenStorage.shared.getFavedStatusWithAddress(token.address)
  }
  
  func updateChartData(_ data: [[Double]]) {
    guard !data.isEmpty else { return }
    self.chartData = data
  }
  
  func generateCandleStickData() -> [CandlestickData] {
    var output: [CandlestickData] = []
    self.tradingViewCandleData.forEach { element in
      //Format open time stamp Time object
      let timestamp = Double(element.openTime / 1000)
      let item = CandlestickData(time: .utc(timestamp: timestamp), open: element.datumOpen, high: element.high, low: element.low, close: element.close)
      
      output.append(item)
    }
    return output
  }
  
  func generateLineData() -> [LineData] {
    var output: [LineData] = []
    self.chartData?.forEach({ element in
      let time = element.first ?? 0
      let timestamp = Double(time / 1000)
      let value = element.last ?? 0
      let item = LineData(time: .utc(timestamp: timestamp), value: value)
      output.append(item)
    })
    return output
    
    
  }
  
  var displayPrice: String {
    return self.numberFormatter.string(from: NSNumber(value: self.detailInfo?.markets[self.currency]?.price ?? 0))?.displayRate(meaningNumber: 2) ?? "0"
  }

  var display24hVol: String {
    return "\(self.detailInfo?.markets[self.currency]?.volume24H ?? 0)"
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
  
  var diplayBalance: String {
    guard !self.hideBalanceStatus else {
      return "********"
    }
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address), let balanceBigInt = BigInt(balance.balance) else { return "---" }
    return balanceBigInt.string(decimals: self.token.decimals, minFractionDigits: 0, maxFractionDigits: min(self.token.decimals, 4)) + " \(self.token.symbol.uppercased())"
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
    return "\(self.detailInfo?.markets[self.currency]?.ath ?? 0)"
  }

  var displayAllTimeLow: String {
    return "\(self.detailInfo?.markets[self.currency]?.atl ?? 0)"
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

  var headerTitle: String {
    if let detailInfo = self.detailInfo {
      return "\(detailInfo.symbol.uppercased())/\(self.currency.uppercased())"
    }
    return "\(self.token.symbol.uppercased())/\(self.currency.uppercased())"
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
    let thousand = number / 1000
    let million = number / 1000000
    let billion = number / 1000000000
    
    if billion >= 1.0 {
      return "\(round(billion*10)/10)B"
    } else if million >= 1.0 {
      return "\(round(million*10)/10)M"
    } else if thousand >= 1.0 {
      return ("\(round(thousand*10/10))K")
    } else {
      return "\(Int(number))"
    }
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
    return "\(selectedPoolDetail?.token0.symbol ?? "")/\(selectedPoolDetail?.token1.symbol ?? "")"
  }
}

enum ChartViewEvent {
  case getChartData(address: String, from: Int, to: Int, currency: String)
  case getCandleChartData(address: String, from: Int, to: Int, currency: String)
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
  @IBOutlet weak var tagView: UIView!
  @IBOutlet weak var chainView: UIView!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainAddressLabel: UILabel!
  @IBOutlet weak var chainViewLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var tagViewTralingToChainViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var infoSegment: SegmentedControl!
  @IBOutlet weak var poolTableView: UITableView!
  @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
  @IBOutlet weak var poolViewTrailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var poolView: UIView!
  @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
  var candleChart: LightweightCharts?
  var lineChart: LightweightCharts?
  @IBOutlet weak var showAllPoolButton: UIButton!
  
  weak var delegate: ChartViewControllerDelegate?
  let viewModel: ChartViewModel
  @IBOutlet weak var poolNameContainerView: UIView!
  @IBOutlet weak var poolNameLabel: UILabel!
  @IBOutlet weak var chartDurationTopSpacing: NSLayoutConstraint!
  fileprivate var tokenPoolTimer: Timer?
  
  var lineOptions: LineSeriesOptions!
  
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
    self.infoSegment.highlightSelectedSegment()
    self.infoSegment.frame = CGRect(x: self.infoSegment.frame.minX, y: self.infoSegment.frame.minY, width: self.infoSegment.frame.width, height: 40)
    self.infoSegment.selectedSegmentIndex = 0
    self.poolTableView.registerCellNib(TokenPoolCell.self)
    self.updateUIPeriodSelectButtons()
    self.titleView.text = self.viewModel.headerTitle
    self.transferButton.rounded(radius: 16)
    self.swapButton.rounded(radius: 16)
    self.investButton.rounded(radius: 16)
    self.favButton.setImage(self.viewModel.displayFavIcon, for: .normal)
    periodChartSelectButtons.forEach { (button) in
      button.rounded(radius: 7)
    }
    if !self.viewModel.canEarn {
      self.investButton.removeFromSuperview()
      self.swapButton.rightAnchor.constraint(equalTo: self.swapButton.superview!.rightAnchor, constant: -26).isActive = true
    }
    
    self.setupTradingView()
  }
  
  fileprivate func setupCandleTradingView() {
    let options = ChartOptions(
      layout: LayoutOptions(backgroundColor: "#181921"),
      crosshair: CrosshairOptions(mode: .normal),
      grid: GridOptions(
        verticalLines: GridLineOptions(color: ChartColor(hex: "2b2c36"), style: LineStyle.solid, visible: true),
        horizontalLines: GridLineOptions(color: ChartColor(hex: "2b2c36"), style: LineStyle.solid, visible: true)
      )
    )
    let chart = LightweightCharts(options: options)
    chart.clearWebViewBackground()
    
    self.chartContainerView.addSubview(chart)
    chart.translatesAutoresizingMaskIntoConstraints = false
    chart.topAnchor.constraint(equalTo: chartContainerView.topAnchor).isActive = true
    chart.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor).isActive = true
    chart.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor).isActive = true
    chart.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor).isActive = true
    
    let series = chart.addCandlestickSeries(options: nil)
    self.viewModel.candleSeries = series
    self.candleChart = chart
  }
  
  fileprivate func setupLineTradingView() {
    let options = ChartOptions(
      layout: LayoutOptions(backgroundColor: "#0F0F0F", fontFamily: "Lato-Regular"),
      rightPriceScale: VisiblePriceScaleOptions(borderColor: "rgba(197, 203, 206, 1)"),
      timeScale: TimeScaleOptions(borderColor: "rgba(197, 203, 206, 1)"),
      crosshair: CrosshairOptions(mode: .normal),
      grid: GridOptions(
        verticalLines: GridLineOptions(color: nil, style: nil, visible: false),
        horizontalLines: GridLineOptions(color: nil, style: nil, visible: false)
      )
    )
    let chart = LightweightCharts(options: options)
    chart.clearWebViewBackground()
    
    self.chartContainerView.addSubview(chart)
    chart.translatesAutoresizingMaskIntoConstraints = false
    chart.topAnchor.constraint(equalTo: chartContainerView.topAnchor).isActive = true
    chart.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor).isActive = true
    chart.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor).isActive = true
    chart.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor).isActive = true
    
    self.lineOptions = LineSeriesOptions(
      lastValueVisible: false, title: nil, visible: true,
      color: ChartColor(viewModel.displayDiffColor ?? UIColor.Kyber.primaryGreenColor),
      lineStyle: LineStyle.solid,
      lineWidth: LineWidth.two,
      lineType: LineType.simple,
      lastPriceAnimation: LastPriceAnimationMode.continuous
    )
    
    self.viewModel.lineSeries = chart.addLineSeries(options: lineOptions)
    self.lineChart = chart
    
  }
  
  private func setupTradingView() {
    if self.viewModel.isLineChartMode {
      self.updateUIPoolName(hidden: true)
      self.candleChart?.removeFromSuperview()
      if let chart = self.lineChart {
        guard !chart.isDescendant(of: self.chartContainerView) else { return }
        self.chartContainerView.addSubview(chart)
        chart.topAnchor.constraint(equalTo: chartContainerView.topAnchor).isActive = true
        chart.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor).isActive = true
        chart.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor).isActive = true
        chart.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor).isActive = true
      } else {
        self.setupLineTradingView()
      }
    } else {
      self.updateUIPoolName(hidden: false)
      self.lineChart?.removeFromSuperview()
      if let chart = candleChart {
        guard !chart.isDescendant(of: self.chartContainerView) else { return }
        self.chartContainerView.addSubview(chart)
        chart.topAnchor.constraint(equalTo: chartContainerView.topAnchor).isActive = true
        chart.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor).isActive = true
        chart.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor).isActive = true
        chart.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor).isActive = true
      } else {
        self.setupCandleTradingView()
      }
    }
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
    self.loadChartData()
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
  
  func hidePoolView() {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
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
    self.loadChartData()
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
    self.viewModel.isLineChartMode = true
    self.loadLineChartData()
    self.setupTradingView()
  }
  

  fileprivate func updateUIChartInfo() {
    self.updateUIPeriodSelectButtons()
  }

  fileprivate func updateUITokenInfo() {
    self.titleView.text = self.viewModel.headerTitle
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
    self.swapButton.backgroundColor = self.viewModel.displayDiffColor
    self.transferButton.backgroundColor = self.viewModel.displayDiffColor
    if self.viewModel.canEarn {
      self.investButton.backgroundColor = self.viewModel.displayDiffColor
    }
    if let image = self.viewModel.tagImage {
      self.tagImageView.image = image
      self.tagLabel.text = self.viewModel.tagLabel
      self.tagView.isHidden = false
      self.chainViewLeadingConstraint.isActive = false
      self.tagViewTralingToChainViewConstraint.isActive = true
    } else {
      self.tagView.isHidden = true
      self.chainViewLeadingConstraint.isActive = true
      self.tagViewTralingToChainViewConstraint.isActive = false
    }
    
    if let chain = ChainType.make(chainID: self.viewModel.chainId) {
      self.chainIcon.image = chain.chainIcon()
    } else {
      self.chainIcon.image = KNGeneralProvider.shared.chainIconImage
    }

    self.chainAddressLabel.text = KNGeneralProvider.shared.currentWalletAddress
    self.lineOptions.color = ChartColor(viewModel.displayDiffColor ?? UIColor.Kyber.primaryGreenColor)
    self.viewModel.lineSeries.applyOptions(options: self.lineOptions)
  }

  fileprivate func loadChartData() {
    if self.viewModel.isLineChartMode {
      self.loadLineChartData()
    } else {
      self.loadCandleChartData(source: self.viewModel.selectedPool.0, quote: self.viewModel.selectedPool.1)
    }
  }
  
  fileprivate func loadLineChartData() {
    let current = NSDate().timeIntervalSince1970
    self.delegate?.chartViewController(self, run: .getChartData(address: self.viewModel.token.address, from: self.viewModel.periodType.getFromTimeStamp(), to: Int(current), currency: self.viewModel.currency))
  }
  
  fileprivate func loadCandleChartData(source: String, quote: String) {
    guard !source.isEmpty, !quote.isEmpty else { return }
    let current = NSDate().timeIntervalSince1970
    self.delegate?.chartViewController(self, run: .getCandleChartData(address: source, from: self.viewModel.periodType.getFromTimeStamp(), to: Int(current), currency: quote))
  }

  fileprivate func loadTokenDetailInfo() {
    self.delegate?.chartViewController(self, run: .getTokenDetailInfo(address: self.viewModel.token.address))
  }
  
  fileprivate func getPoolList() {
    self.delegate?.chartViewController(self, run: .getPoolList(address: self.viewModel.token.address, chainId: self.viewModel.chainId ))
    self.tokenPoolTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds15,
      repeats: true,
      block: { [weak self] _ in
        guard let `self` = self else { return }
        self.delegate?.chartViewController(self, run: .getPoolList(address: self.viewModel.token.address, chainId: self.viewModel.chainId ))
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
    self.viewModel.poolData = poolData
    self.updatePoolTableHeight()
    self.showAllPoolButton.isHidden = poolData.count <= 5
    self.poolTableView.reloadData()
    self.viewModel.selectedPoolDetail = poolData.first
  }

  func coordinatorDidUpdateChartData(_ data: [[Double]]) {
    self.noDataLabel.isHidden = !data.isEmpty
    self.viewModel.updateChartData(data)
    self.updateUIChartInfo()
    let data = self.viewModel.generateLineData()
    self.viewModel.lineSeries.setData(data: data)
    self.lineOptions.color = ChartColor(viewModel.displayDiffColor ?? UIColor.Kyber.primaryGreenColor)
    self.viewModel.lineSeries.applyOptions(options: self.lineOptions)
  }

  func coordinatorFailUpdateApi(_ error: Error) {
    self.showErrorTopBannerMessage(with: "", message: error.localizedDescription)
  }

  func coordinatorDidUpdateTokenDetailInfo(_ detailInfo: TokenDetailInfo) {
    self.viewModel.detailInfo = detailInfo
    self.updateUITokenInfo()
    self.updateUIChartInfo()
  }
  
  func coordinatorDidUpdateTradingViewData(_ data: [TradingViewData]) {
    self.viewModel.tradingViewCandleData = data
    let data = self.viewModel.generateCandleStickData()
    self.viewModel.candleSeries.setData(data: data)
  }
}

extension ChartViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.poolData.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(TokenPoolCell.self, indexPath: indexPath)!
    let poolData = self.viewModel.poolData[indexPath.row]
    cell.updateUI(poolDetail: poolData, baseTokenSymbol: self.viewModel.token.symbol)
    return cell
  }
}

extension ChartViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    self.viewModel.isLineChartMode = false
    let poolData = self.viewModel.poolData[indexPath.row]
    self.viewModel.selectedPoolDetail = poolData
    let source = poolData.token0.address
    let quote = poolData.token1.address
    self.loadCandleChartData(source: source, quote: quote)
    self.setupTradingView()
    self.containScrollView.setContentOffset(CGPoint.zero, animated: true)
  }
}

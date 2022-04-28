//
//  ChartViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/24/21.
//

import UIKit
import SwiftChart
import BigInt

class ChartViewModel {
  var dataSource: [(x: Double, y: Double)] = []
  var xLabels: [Double] = []
  let token: Token
  var periodType: ChartPeriodType = .oneDay
  var detailInfo: TokenDetailInfo?
  var chartData: [[Double]]?
  var chartOriginTimeStamp: Double = 0
  var currency: String
  let currencyMode: CurrencyMode
  var isFaved: Bool
  var hideBalanceStatus: Bool = UserDefaults.standard.bool(forKey: Constants.hideBalanceKey) {
    didSet {
      UserDefaults.standard.set(self.hideBalanceStatus, forKey: Constants.hideBalanceKey)
    }
  }
  let lendingTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.lendingTokensStoreFileName, as: [TokenData].self)

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()

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
    guard let balance = BalanceStorage.shared.balanceForAddress(self.token.address), let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.token.address), let balanceBigInt = BigInt(balance.balance) else { return "---" }
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
  @IBOutlet weak var chartView: Chart!
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
  weak var delegate: ChartViewControllerDelegate?
  let viewModel: ChartViewModel

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
    self.chartView.showYLabelsAndGrid = false
    self.chartView.labelColor = UIColor(red: 164, green: 171, blue: 187)
    self.chartView.labelFont = UIFont.Kyber.latoRegular(with: 10)
    self.chartView.axesColor = .clear
    self.chartView.gridColor = .clear
    self.chartView.backgroundColor = .clear
    self.chartView.delegate = self
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
  }

  func setupConstraints() {
    topBarHeight?.constant = UIScreen.statusBarHeight + 36 * 2 + 24
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.loadChartData()
    self.loadTokenDetailInfo()
    self.updateUIChartInfo()
    self.updateUITokenInfo()
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
  
  
  fileprivate func updateUIChartInfo() {
    self.updateUIPeriodSelectButtons()
  }

  fileprivate func updateUITokenInfo() {
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
    } else {
      self.tagView.isHidden = true
    }
  }

  fileprivate func loadChartData() {
    let current = NSDate().timeIntervalSince1970
    self.delegate?.chartViewController(self, run: .getChartData(address: self.viewModel.token.address, from: self.viewModel.periodType.getFromTimeStamp(), to: Int(current), currency: self.viewModel.currency))
  }

  fileprivate func loadTokenDetailInfo() {
    self.delegate?.chartViewController(self, run: .getTokenDetailInfo(address: self.viewModel.token.address))
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

  func coordinatorDidUpdateChartData(_ data: [[Double]]) {
    self.noDataLabel.isHidden = !data.isEmpty
    self.viewModel.updateChartData(data)
    self.chartView.removeAllSeries()
    self.chartView.add(self.viewModel.series)
    self.chartView.xLabels = self.viewModel.xLabels
    self.updateUIChartInfo()
    self.chartView.xLabelsFormatter = { (labelIndex: Int, labelValue: Double) -> String in
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
        return "\(hour):\(minutes)"
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

  func coordinatorDidUpdateTokenDetailInfo(_ detailInfo: TokenDetailInfo) {
    self.viewModel.detailInfo = detailInfo
    self.updateUITokenInfo()
    self.chartView.removeAllSeries()
    self.chartView.add(self.viewModel.series)
    self.updateUIChartInfo()
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

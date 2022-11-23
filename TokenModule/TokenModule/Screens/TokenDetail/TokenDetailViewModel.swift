//
//  TokenDetailViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation
import Services
import Charts
import UIKit
import BigInt
import DesignSystem
import Utilities
import Dependencies
import AppState
import BaseWallet

class TokenDetailViewModel {
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
  
  var chain: ChainType
  var chainID: Int
  
  var hideBalanceStatus: Bool {
    get {
      return UserDefaults.standard.bool(forKey: Constants.hideBalanceKey)
    }
    set {
      return UserDefaults.standard.set(newValue, forKey: Constants.hideBalanceKey)
    }
  }
  
  var isExpandingPoolTable: Bool = false
  
  var isFaved: Bool {
    return AppDependencies.tokenStorage.isFavoriteToken(address: token.address)
  }

  let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 18
    formatter.minimumFractionDigits = 18
    formatter.minimumIntegerDigits = 1
    return formatter
  }()
  
  var selectedPoolDetail: TokenPoolDetail?
  var lineChartData: LineChartData?
  
  var onTokenInfoUpdated: (() -> ())?
  var onTokenInfoLoadedFail: (() -> ())?
  var onChartDataUpdated: (() -> ())?
  var onPoolListUpdated: (() -> ())?
  
  let service = TokenService()

  init(token: Token, chainID: Int, currencyMode: CurrencyMode) {
    self.token = token
    self.currencyMode = currencyMode
    self.chainID = chainID
    self.chain = ChainType.make(chainID: chainID) ?? AppState.shared.currentChain
    self.currency = currencyMode.toString(chain: chain)
  }
  
  func updateChartData(_ data: [[Double]]) {
    guard !data.isEmpty else { return }
    self.chartData = data
    let dataEntry = data.map { item -> ChartDataEntry in
      let timeStamp = item.first ?? 0.0
      let value = item.last ?? 0.0
      return ChartDataEntry(x: timeStamp, y: value)
    }
    
    let diff: Double = {
      let firstPoint = data.first?.last ?? 0.0
      let lastPoint = data.last?.last ?? 0.0
      return lastPoint - firstPoint
    }()
    
    let dataSet = LineChartDataSet(entries: dataEntry, label: "")
    dataSet.lineDashLengths = nil
    dataSet.highlightLineDashLengths = nil
    dataSet.setCircleColor(.black)
    dataSet.setColors(.clear)
    dataSet.gradientPositions = [0, 40, 100]
    dataSet.lineWidth = 1
    dataSet.circleRadius = 3
    dataSet.drawCircleHoleEnabled = false
    dataSet.valueFont = .systemFont(ofSize: 9)
    dataSet.formLineDashLengths = nil
    dataSet.formLineWidth = 1
    dataSet.formSize = 15
    
    dataSet.drawValuesEnabled = false
    dataSet.mode = .linear
    dataSet.drawCirclesEnabled = false
    dataSet.isDrawLineWithGradientEnabled = true
    dataSet.highlightEnabled = true
    
    
    let redGradientColors = [ChartColorTemplates.colorFromString("#00ff0000").cgColor,
                               ChartColorTemplates.colorFromString("#ffff0000").cgColor]
    
    let greenGradientColors = [ChartColorTemplates.colorFromString("#1de9b6").cgColor,
                          ChartColorTemplates.colorFromString("#8EF4DA").cgColor]
    
    let gradientColors = diff > 0 ? greenGradientColors : redGradientColors
    let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
    dataSet.fillAlpha = 1
    dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90)
    dataSet.drawFilledEnabled = true
    

    let data = LineChartData(dataSet: dataSet)
    
    self.lineChartData = data
  }
  
  var displayPrice: String {
    let priceInDouble = self.detailInfo?.markets[self.currency]?.price ?? 0
    let priceInBigInt = BigInt(priceInDouble * pow(10, 18))
    return "$" + NumberFormatUtils.usdValueFormat(value: priceInBigInt, decimals: 18)
  }

  var display24hVol: String {
    let volume24H = self.detailInfo?.markets[self.currency]?.volume24H ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.volFormat(number: volume24H) + self.currencyMode.suffixSymbol(chain: chain)
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
    guard let balance = AppDependencies.balancesStorage.getBalance(address: self.token.address) else { return "---" }
    let balanceString = NumberFormatUtils.balanceFormat(value: balance, decimals: self.token.decimals)
    return balanceString + " \(self.token.symbol.uppercased())"
  }

  var displayUSDBalance: String {
    guard let balance = AppDependencies.balancesStorage.getBalance(address: self.token.address) else {
      return "---"
    }
    let price = getTokenLastPrice(self.currencyMode)
    let rateBigInt = BigInt(price * pow(10.0, 18.0))
    let valueBigInt = balance * rateBigInt / BigInt(10).power(18)
    return self.currencyMode.symbol() + NumberFormatUtils.usdValueFormat(value: valueBigInt, decimals: token.decimals)
  }

  var marketCap: Double {
    return self.detailInfo?.markets[self.currency]?.marketCap ?? 0
  }
  
  var displayMarketCap: String {
    return self.currencyMode.symbol() + NumberFormatUtils.volFormat(number: self.marketCap) + self.currencyMode.suffixSymbol(chain: chain)
  }
  
  var displayAllTimeHigh: String {
    let ath = self.detailInfo?.markets[self.currency]?.ath ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.allTimeHighAndLowFormat(number: ath) + self.currencyMode.suffixSymbol(chain: chain)
  }

  var displayAllTimeLow: String {
    let atl = self.detailInfo?.markets[self.currency]?.atl ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.allTimeHighAndLowFormat(number: atl) + self.currencyMode.suffixSymbol(chain: chain)
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
      NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 14)
    ], range: NSRange(location: 0, length: attributedString.length)
    )
    return string
  }

  var headerTitle: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let titleAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!,
      NSAttributedString.Key.font: UIFont.karlaBold(ofSize: 20),
      NSAttributedString.Key.kern: 0.0,
    ]
    let subTitleAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.foregroundColor: UIColor(named: "normalTextColor")!,
      NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 18),
      NSAttributedString.Key.kern: 0.0,
    ]
    var titleString = ""
    if let detailInfo = self.detailInfo {
      titleString = detailInfo.symbol.isEmpty ? "\(self.token.symbol.uppercased())" : "\(detailInfo.symbol.uppercased())"
    } else {
      titleString = "\(self.token.symbol.uppercased())"
    }
    var subTitleString = ""
    if let detailInfo = self.detailInfo {
      subTitleString = detailInfo.name.isEmpty ? "\(self.token.name.uppercased())" : "\(detailInfo.name.uppercased())"
    } else {
      subTitleString = "\(self.token.name.uppercased())"
    }
    attributedString.append(NSAttributedString(string: "\(titleString) ", attributes: titleAttributes))
    attributedString.append(NSAttributedString(string: "\(subTitleString)", attributes: subTitleAttributes))
    return attributedString
  }
  
  var tagImage: UIImage? {
    guard let tag = self.detailInfo?.tag else { return nil }
     if tag == "VERIFIED" {
       return UIImage(named: "blueTick_icon")
     } else if tag == "PROMOTION" {
       return UIImage(named: "green-checked-tag-icon")
     } else if tag == "SCAM" {
       return UIImage(named: "warning-tag-icon")
     } else if tag == "UNVERIFIED" {
       return nil
     }
     return nil
   }
  
  var tagLabel: String {
    guard let tag = self.detailInfo?.tag else { return "" }
     if tag == "VERIFIED" {
       return "Verified Token".toBeLocalised()
     } else if tag == "PROMOTION" {
       return "New Token".toBeLocalised()
     } else if tag == "SCAM" {
       return "Untrusted Token".toBeLocalised()
     } else if tag == "UNVERIFIED" {
       return ""
     }
     return ""
  }

  func displayChartDetaiInfoAt(x: Double, y: Double) -> NSAttributedString {
    let price = y
    let timestamp = x
    let date = Date(timeIntervalSince1970: timestamp * 0.001)
    let dateFormater = DateFormatterUtil.shared.chartViewDateFormatter
    let dateString = dateFormater.string(from: date)
    let normalAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.karlaReguler(ofSize: 10),
      NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor,
    ]
    let boldAttributes: [NSAttributedString.Key: Any] = [
      NSAttributedString.Key.font: UIFont.karlaBold(ofSize: 10),
      NSAttributedString.Key.foregroundColor: AppTheme.current.primaryTextColor,
    ]
    let priceBigInt = BigInt(price * pow(10.0, 18.0))

    let attributedText = NSMutableAttributedString()
    attributedText.append(NSAttributedString(string: dateString + " ", attributes: boldAttributes))
    attributedText.append(NSAttributedString(string: "  Price" + ": ", attributes: boldAttributes))

    let valueString = NumberFormatUtils.usdValueFormat(value: priceBigInt, decimals: 18)
    let displayString = !self.currencyMode.symbol().isEmpty ? self.currencyMode.symbol() + valueString : valueString + self.currencyMode.suffixSymbol(chain: chain)
    
    attributedText.append(NSAttributedString(string: displayString, attributes: normalAttributes))

    return attributedText
  }
  
  var displayFavIcon: UIImage? {
    return self.isFaved ? UIImage(named: "fav_star_icon") : UIImage(named: "unFav_star_icon")
  }
  
  var canEarn: Bool {
    return AppDependencies.tokenStorage.isTokenEarnable(address: token.address)
  }
  
  var selectedPoolPair: String {
    guard let selectedPoolDetail = selectedPoolDetail else {
      return ""
    }
    if selectedPoolDetail.token1.address.lowercased() == baseTokenAddress.lowercased() {
      return "\(selectedPoolDetail.token1.symbol)/\(selectedPoolDetail.token0.symbol)"
    } else {
      return "\(selectedPoolDetail.token0.symbol)/\(selectedPoolDetail.token1.symbol)"
    }
  }
  
  var selectedPoolName: String? {
    return selectedPoolDetail?.name
  }
  
  var baseTokenAddress: String {
    if token.isQuoteToken() {
      let wsymbol = "W" + self.token.symbol
      if let wtoken = AppDependencies.tokenStorage.getAllSupportedTokens().first(where: { $0.symbol == wsymbol }) {
        return wtoken.address
      }
    }
    return token.address
  }
  
  func getTokenLastPrice(_ mode: CurrencyMode) -> Double {
    switch mode {
    case .usd:
      return detailInfo?.markets["usd"]?.price ?? 0
    case .eth:
      return detailInfo?.markets["eth"]?.price ?? 0
    case .btc:
      return detailInfo?.markets["btc"]?.price ?? 0
    default:
      return detailInfo?.markets[chain.quoteToken().lowercased()]?.price ?? 0
    }
  }
  
  func loadTokenDetailInfo(isFirstLoad: Bool) {
    service.getTokenDetail(address: token.address, chainPath: chain.apiChainPath()) { [weak self] tokenDetail in
      if let tokenDetail = tokenDetail {
        self?.detailInfo = tokenDetail
        self?.onTokenInfoUpdated?()
      } else {
        if isFirstLoad {
          self?.onTokenInfoLoadedFail?()
        }
      }
    }
  }
  
  func loadChartData() {
    service.getChartData(chainPath: chain.customRPC().apiChainPath, tokenAddress: token.address, quote: currency, from: periodType.getFromTimeStamp(), to: Int(Date().timeIntervalSince1970)) { [weak self] data in
      self?.updateChartData(data)
      self?.onChartDataUpdated?()
    }
  }
  
  func loadPoolList() {
    var address = token.address
    if token.isQuoteToken() {
      let wsymbol = "W" + token.symbol
      if let wtoken = AppDependencies.tokenStorage.getAllSupportedTokens().first(where: { $0.symbol == wsymbol }) {
        address = wtoken.address
      }
    }
    service.getPoolList(tokenAddress: address, chainID: chainID) { [weak self] pools in
      self?.poolData = pools
      self?.onPoolListUpdated?()
    }
  }
  
}

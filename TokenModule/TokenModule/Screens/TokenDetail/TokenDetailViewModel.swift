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
  var periodType: ChartPeriodType = .oneDay
  
  var chartData: [[Double]]?
  var chartOriginTimeStamp: Double = 0

  var currency: String
  let currencyMode: CurrencyMode
  
  var chain: ChainType
  
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
    return AppDependencies.tokenStorage.isFavoriteToken(address: address)
  }
  
  var isQuoteToken: Bool {
    if let tokenDetail = tokenDetail {
      return tokenDetail.symbol.uppercased() == chain.quoteToken().uppercased()
    }
    return false
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
  var onDataLoaded: (() -> ())?
  var onChartDataUpdated: (() -> ())?
  
  let service = TokenService()
  var address: String
  var tokenDetail: TokenDetailInfo?

  init(address: String, chain: ChainType, currencyMode: CurrencyMode) {
    self.address = address
    self.currencyMode = currencyMode
    self.chain = chain
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
    let priceInDouble = tokenDetail?.markets[self.currency]?.price ?? 0
    let priceInBigInt = BigInt(priceInDouble * pow(10, 18))
    return "$" + NumberFormatUtils.usdValueFormat(value: priceInBigInt, decimals: 18)
  }

  var display24hVol: String {
    let volume24H = tokenDetail?.markets[self.currency]?.volume24H ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.volFormat(number: volume24H) + self.currencyMode.suffixSymbol(chain: chain)
  }

  var diffPercent: Double {
    switch self.periodType {
    case .oneDay:
      return tokenDetail?.markets[self.currency]?.priceChange24HPercentage ?? 0
    case .sevenDay:
      return tokenDetail?.markets[self.currency]?.priceChange7DPercentage ?? 0
    case .oneMonth:
      return tokenDetail?.markets[self.currency]?.priceChange30DPercentage ?? 0
    case .threeMonth:
      return tokenDetail?.markets[self.currency]?.priceChange200DPercentage ?? 0
    case .oneYear:
      return tokenDetail?.markets[self.currency]?.priceChange1YPercentage ?? 0
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
    guard let tokenDetail = tokenDetail else {
      return ""
    }
    guard !self.hideBalanceStatus else {
      return "********"
    }
    guard let balance = AppDependencies.balancesStorage.getBalance(address: self.address) else { return "---" }
    let balanceString = NumberFormatUtils.balanceFormat(value: balance, decimals: tokenDetail.decimals)
    return balanceString + " \(tokenDetail.symbol.uppercased())"
  }

  var displayUSDBalance: String {
    guard let tokenDetail = tokenDetail else {
      return ""
    }
    guard let balance = AppDependencies.balancesStorage.getBalance(address: self.address) else {
      return "---"
    }
    let price = getTokenLastPrice(self.currencyMode)
    let rateBigInt = BigInt(price * pow(10.0, 18.0))
    let valueBigInt = balance * rateBigInt / BigInt(10).power(18)
    return self.currencyMode.symbol() + NumberFormatUtils.usdValueFormat(value: valueBigInt, decimals: tokenDetail.decimals)
  }

  var marketCap: Double {
    return tokenDetail?.markets[self.currency]?.marketCap ?? 0
  }
  
  var displayMarketCap: String {
    return self.currencyMode.symbol() + NumberFormatUtils.volFormat(number: self.marketCap) + self.currencyMode.suffixSymbol(chain: chain)
  }
  
  var displayAllTimeHigh: String {
    let ath = tokenDetail?.markets[self.currency]?.ath ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.allTimeHighAndLowFormat(number: ath) + self.currencyMode.suffixSymbol(chain: chain)
  }

  var displayAllTimeLow: String {
    let atl = tokenDetail?.markets[self.currency]?.atl ?? 0
    return self.currencyMode.symbol() + NumberFormatUtils.allTimeHighAndLowFormat(number: atl) + self.currencyMode.suffixSymbol(chain: chain)
  }

  var displayDescription: String {
    return self.tokenDetail?.resultDescription ?? ""
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
    guard let token = tokenDetail else { return NSAttributedString() }
    
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
    
    attributedString.append(NSAttributedString(string: token.symbol.uppercased(), attributes: titleAttributes))
    attributedString.append(NSAttributedString(string: " "))
    attributedString.append(NSAttributedString(string: token.name.uppercased(), attributes: subTitleAttributes))
    
    return attributedString
  }
  
  var tagImage: UIImage? {
    guard let tag = tokenDetail?.tag else { return nil }
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
    guard let tag = tokenDetail?.tag else { return "" }
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
    guard let tokenDetail = tokenDetail else {
      return false
    }
    return AppDependencies.tokenStorage.isTokenEarnable(address: tokenDetail.address)
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
    guard let token = tokenDetail else {
      return ""
    }
    if token.symbol.uppercased() == chain.quoteToken().uppercased() {
      let wsymbol = "W" + token.symbol
      if let wtoken = AppDependencies.tokenStorage.getAllSupportedTokens().first(where: { $0.symbol == wsymbol }) {
        return wtoken.address
      }
    }
    return token.address
  }
  
  func getTokenLastPrice(_ mode: CurrencyMode) -> Double {
    switch mode {
    case .usd:
      return tokenDetail?.markets["usd"]?.price ?? 0
    case .eth:
      return tokenDetail?.markets["eth"]?.price ?? 0
    case .btc:
      return tokenDetail?.markets["btc"]?.price ?? 0
    default:
      return tokenDetail?.markets[chain.quoteToken().lowercased()]?.price ?? 0
    }
  }
  
  func loadTokenDetailInfo(completion: @escaping () -> ()) {
    service.getTokenDetail(address: address, chainPath: chain.apiChainPath()) { [weak self] tokenDetail in
      if let tokenDetail = tokenDetail {
        self?.tokenDetail = tokenDetail
      }
      completion()
    }
  }
  
  func loadChartData(completion: @escaping () -> ()) {
    service.getChartData(chainPath: chain.customRPC().apiChainPath, tokenAddress: address, quote: currency, from: periodType.getFromTimeStamp(), to: Int(Date().timeIntervalSince1970)) { [weak self] data in
      self?.updateChartData(data)
      completion()
    }
  }
  
  func loadPoolList(completion: @escaping () -> ()) {
    guard let token = tokenDetail else {
      return
    }
      
    var address = self.address
    if isQuoteToken {
      let wsymbol = "W" + token.symbol
      if let wtoken = AppDependencies.tokenStorage.getAllSupportedTokens().first(where: { $0.symbol == wsymbol }) {
        address = wtoken.address
      }
    }
    service.getPoolList(tokenAddress: address, chainID: chain.getChainId()) { [weak self] pools in
      self?.poolData = pools
      completion()
    }
  }
  
  func createToken() -> Token? {
    guard let tokenDetail = tokenDetail else {
      return nil
    }
    return Token(name: tokenDetail.name, symbol: tokenDetail.symbol, address: tokenDetail.address, decimals: tokenDetail.decimals, logo: tokenDetail.logo)
  }
  
  func loadData() {
    loadTokenDetailInfo { [weak self] in
      guard let self = self else { return }
      if self.tokenDetail != nil {
        self.loadChartData {
          self.loadPoolList {
            self.onDataLoaded?()
          }
        }
      } else {
        self.onTokenInfoLoadedFail?()
      }
    }
  }

}

//
//  ChartLoadRequest.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 27/06/2022.
//

import Foundation
import Utilities

struct ChartLoadRequest {
  var symbol: String?
  var chain: String?
  var baseAddress: String?
  var quoteAddress: String?
  var period: Period = .d1
  var chartType: ChartType = .candles
  var apiURL: String = ""
  var fullscreen: Bool = false
  
  func buildChartURL(withBaseURL url: URL) -> URL {
    return url
      .appending("symbol", value: symbol)
      .appending("chain", value: chain)
      .appending("baseAddress", value: baseAddress)
      .appending("quoteAddress", value: quoteAddress)
      .appending("interval", value: period.interval)
      .appending("chartType", value: "\(chartType.rawValue)")
      .appending("apiURL", value: apiURL)
      .appending("fullscreen", value: "\(fullscreen)")
  }
}

class ChartLoadRequestBuilder {
  var symbol: String?
  var chain: String?
  var baseAddress: String?
  var quoteAddress: String?
  var period: Period = .d1
  var chartType: ChartType = .candles
  var apiURL: String = ""
  var fullscreen: Bool = false
  
  func symbol(_ symbol: String) -> ChartLoadRequestBuilder {
    self.symbol = symbol
    return self
  }
  
  func chain(_ chain: String) -> ChartLoadRequestBuilder {
    self.chain = chain
    return self
  }
  
  func baseAddress(_ baseAddress: String) -> ChartLoadRequestBuilder {
    self.baseAddress = baseAddress
    return self
  }
  
  func quoteAddress(_ quoteAddress: String) -> ChartLoadRequestBuilder {
    self.quoteAddress = quoteAddress
    return self
  }
  
  func period(_ period: Period) -> ChartLoadRequestBuilder {
    self.period = period
    return self
  }
  
  func chartType(_ chartType: ChartType) -> ChartLoadRequestBuilder {
    self.chartType = chartType
    return self
  }
  
  func apiURL(_ apiURL: String) -> ChartLoadRequestBuilder {
    self.apiURL = apiURL
    return self
  }
  
  func fullscreen(_ fullscreen: Bool) -> ChartLoadRequestBuilder {
    self.fullscreen = fullscreen
    return self
  }
  
  func build() -> ChartLoadRequest {
    return ChartLoadRequest(
      symbol: symbol,
      chain: chain,
      baseAddress: baseAddress,
      quoteAddress: quoteAddress,
      period: period,
      chartType: chartType,
      apiURL: apiURL,
      fullscreen: fullscreen
    )
  }
  
}

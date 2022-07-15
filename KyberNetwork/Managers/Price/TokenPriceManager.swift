//
//  TokenPriceManager.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 14/07/2022.
//

import Foundation
import RealmSwift

class TokenPriceManager {
  
  static let shared = TokenPriceManager()
  
  private(set) var config: TokenPriceManagerConfig {
    didSet {
      didUpdateConfig()
    }
  }
  
  private var timer: Timer?
  var realm: Realm!
  private let marketService: MarketService
  let prefix = "token_price_"
  private(set) var chains: [ChainType] = []
  
  private init() {
    self.config = TokenPriceManagerConfig()
    self.marketService = MarketService()
    self.initializeRealm()
  }
  
  private func initializeRealm() {
    let env = "\(KNEnvironment.default)"
    var config = Realm.Configuration()
    config.schemaVersion = 1
    config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent(prefix + env)
    self.realm = try! Realm(configuration: config)
  }
  
  func configure() {
    timer = Timer.scheduledTimer(
      withTimeInterval: config.fetchInterval,
      repeats: true, block: { [weak self] _ in
        self?.fetchTokenPrices()
      }
    )
  }
  
  func fetchTokenPrices() {
    chains.forEach { chain in
      let quotes = ["btc", "usd"] + [chain.quoteToken().lowercased()]
      marketService.getTokenPrices(chainPath: chain.customRPC().apiChainPath, quotes: quotes) { [weak self] tokens in
        let objects = tokens.map { KTokenObject(chainID: chain.getChainId(), dto: $0) }
        self?.realm.writeAsync {
          self?.realm.add(objects, update: .all)
        }
      }
    }
  }
  
  func setChains(chains: [ChainType]) {
    self.chains = chains
  }

  func didUpdateConfig() {
    timer?.invalidate()
    timer = nil
    configure()
  }
  
}

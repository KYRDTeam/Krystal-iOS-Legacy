// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import Moya
import Sentry

class KNLoadBalanceCoordinator {

  fileprivate var session: KNSession! //TODO: use general provider to load balance instead of external provider

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false

  var otherTokensBalance: [String: Balance] = [:]

  fileprivate var fetchBalanceTimer: Timer?
  fileprivate var fetchTotalBalanceTimer: Timer?
  fileprivate var isFetchNonSupportedBalance: Bool = false

  fileprivate var lastRefreshTime: Date = Date()

  deinit {
    self.exit()
  }

  init(session: KNSession) {
    self.session = session
  }

  func restartNewSession(_ session: KNSession) {
    self.session = session
    self.resume()
  }

  func loadAllBalances() {
    let tx = SentrySDK.startTransaction(
      name: "load-balance-request",
      operation: "load-balance-operation"
    )
    let group = DispatchGroup()
    group.enter()
    let span1 = tx.startChild(operation: "load-lending-balances")
    self.loadLendingBalances { success in
      span1.finish()
      group.leave()
    }
    group.enter()
    let span2 = tx.startChild(operation: "load-lending-distribution-balances")
    self.loadLendingDistributionBalance { success in
      span2.finish()
      group.leave()
    }

    group.enter()
    let span3 = tx.startChild(operation: "load-token-balances")
    self.loadTokenBalancesFromApi { success in
      span3.finish()
      group.leave()
    }
    group.enter()
    let span4 = tx.startChild(operation: "load-nft-balances")
    self.loadNFTBalance { success in
      span4.finish()
      group.leave()
    }
    
    group.enter()
    let span5 = tx.startChild(operation: "load-custom-nft-balances")
    self.loadCustomNFTBalane { success in
      span5.finish()
      group.leave()
    }

    group.enter()
    let span6 = tx.startChild(operation: "load-liquidity-pool")
    self.loadLiquidityPool { success in
      span6.finish()
      group.leave()
    }

    group.enter()
    let span7 = tx.startChild(operation: "load-total-balance")
    self.loadTotalBalance { success in
      span7.finish()
      group.leave()
    }

    group.notify(queue: .global()) {
      tx.finish()
    }
  }

  func resume() {
    fetchBalanceTimer?.invalidate()
    fetchBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds30,
      repeats: true,
      block: { [weak self] timer in
        self?.loadAllBalances()
      }
    )
    self.loadAllBalances()
    fetchTotalBalanceTimer?.invalidate()
    fetchTotalBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds60,
      repeats: true,
      block: { [weak self] _ in
        self?.loadTotalBalance(forceSync: true, completion: { _ in

        })
      })
    self.loadTotalBalance(forceSync: true, completion: { _ in

    })
  }

  func pause() {
    fetchOtherTokensBalanceTimer?.invalidate()
    fetchOtherTokensBalanceTimer = nil
    isFetchingOtherTokensBalance = true

    fetchBalanceTimer?.invalidate()
    fetchBalanceTimer = nil
    isFetchNonSupportedBalance = true
    
    fetchTotalBalanceTimer?.invalidate()
    fetchTotalBalanceTimer = nil
  }

  func exit() {
    pause()
  }


  @objc func fetchNonSupportedTokensBalancesNew(_ sender: Any?) {
    if self.isFetchNonSupportedBalance { return }
    self.isFetchNonSupportedBalance = true
    let tokenContracts = self.session.tokenStorage.tokens.filter({ return !$0.isETH && !$0.isSupported }).map({ $0.contract })

    let tokens = tokenContracts.map({ return Address(string: $0)! })

    self.fetchTokenBalances(tokens: tokens) { [weak self] result in
      guard let `self` = self else { return }
      self.isFetchNonSupportedBalance = false
      switch result {
      case .success(let isLoaded):
        if !isLoaded {
          self.fetchNonSupportedTokensBalancesChunked()
        } else {
          let tokens = self.session.tokenStorage.tokens.filter({ return !$0.isSupported && $0.valueBigInt == BigInt(0) })
          self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
        }
      case .failure(let error):
        if error.code == NSURLErrorNotConnectedToInternet { return }
        self.fetchNonSupportedTokensBalancesChunked()
      }
    }
  }

  func fetchNonSupportedTokensBalancesChunked(chunkedNum: Int = 20) {
    if self.isFetchNonSupportedBalance { return }
    self.isFetchNonSupportedBalance = true
    let sortedTokens = self.session.tokenStorage.tokens.filter({ return !$0.isETH && !$0.isSupported }).sorted { (left, right) -> Bool in
      return left.value > right.value
    }
    let sortedAddress = sortedTokens.map({ $0.contract }).map({ return Address(string: $0)! })
    let chunkedAddress = sortedAddress.chunked(into: chunkedNum)
    let group = DispatchGroup()
    chunkedAddress.forEach { (addresses) in
      group.enter()
      self.fetchTokenBalances(tokens: addresses) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let isLoaded):
          if !isLoaded {
            self.fetchNonSupportedTokensBalances(addresses: addresses)
          } else {
            let tokens = self.session.tokenStorage.tokens.filter({ return !$0.isSupported && $0.valueBigInt == BigInt(0) })
            self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
          }
        case .failure(let error):
          if error.code == NSURLErrorNotConnectedToInternet { return }
          self.fetchNonSupportedTokensBalances(addresses: addresses)
        }
        group.leave()
      }
    }
    group.notify(queue: .main) {
      self.isFetchNonSupportedBalance = false
    }
  }

  func fetchNonSupportedTokensBalances(addresses: [Address]) {
    guard let provider = self.session.externalProvider else {
      return
    }
    var isBalanceChanged: Bool = false
    let currentWallet = self.session.wallet
    var zeroBalanceAddresses: [String] = []
    let group = DispatchGroup()
    var delay = 0.2
    self.isFetchNonSupportedBalance = true
    addresses.forEach { (address) in
      group.enter()
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        if self.session == nil { group.leave(); return }
        provider.getTokenBalance(for: address, completion: { [weak self] result in
          guard let `self` = self else { group.leave(); return }
          if self.session == nil || currentWallet != self.session.wallet { group.leave(); return }
          switch result {
          case .success(let bigInt):
            let balance = Balance(value: bigInt)
            if self.otherTokensBalance[address.description.lowercased()] == nil || self.otherTokensBalance[address.description.lowercased()]!.value != bigInt {
              isBalanceChanged = true
            }
            self.otherTokensBalance[address.description.lowercased()] = balance
            self.session.tokenStorage.updateBalance(for: address, balance: bigInt)
            if bigInt == BigInt(0) { zeroBalanceAddresses.append(address.description.lowercased()) }
            NSLog("---- Balance: Fetch token balance for contract \(address.description) successfully: \(bigInt.shortString(decimals: 0))")
          case .failure(let error):
            NSLog("---- Balance: Fetch token balance failed with error: \(error.description). ----")
          }
          group.leave()
        })
      }
      delay += 0.2
    }

    group.notify(queue: .main) {
      self.isFetchNonSupportedBalance = false
      if isBalanceChanged {
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      }
      if !zeroBalanceAddresses.isEmpty {
        let tokens = self.session.tokenStorage.tokens.filter({
          return zeroBalanceAddresses.contains($0.contract.lowercased())
        })
        self.session.tokenStorage.disableUnsupportedTokensWithZeroBalance(tokens: tokens)
      }
    }
  }

  fileprivate func fetchTokenBalances(tokens: [Address], completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    if tokens.isEmpty {
      completion(.success(true))
      return
    }
    var isBalanceChanged = false
    provider.getMultipleERC20Balances(tokens) { [weak self] result in
      guard let `self` = self else {
        completion(.success(false))
        return
      }
      switch result {
      case .success(let values):
        if values.count == tokens.count {
          for id in 0..<values.count {
            let balance = Balance(value: values[id])
            let addr = tokens[id].description.lowercased()
            if self.otherTokensBalance[addr.lowercased()] == nil || self.otherTokensBalance[addr.lowercased()]!.value != values[id] {
              isBalanceChanged = true
            }
            self.otherTokensBalance[addr.lowercased()] = balance
            self.session.tokenStorage.updateBalance(for: tokens[id], balance: values[id])
            if isDebug {
              NSLog("---- Balance: Fetch token balance for contract \(addr) successfully: \(values[id].shortString(decimals: 0))")
            }
          }
          if isBalanceChanged {
            KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          }
          completion(.success(true))
        } else {
          completion(.success(false))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  //MARK:-new balance load implementation
  func loadAllTokenBalance() {
    let tokens = KNSupportedTokenStorage.shared.getSupportedTokens()
    var erc20Address: [Address] = []
    tokens.forEach { (token) in
      if let address = Address(string: token.address) {
        erc20Address.append(address)
      }
    }
    guard !erc20Address.isEmpty else {
      return
    }
    KNGeneralProvider.shared.getMutipleERC20Balances(for: self.session.wallet.address, tokens: erc20Address) { result in
      switch result {
      case .success(let values):
        if values.count == erc20Address.count {
          var balances: [TokenBalance] = []
          for id in 0..<values.count {
            let balance = TokenBalance(address: erc20Address[id].description.lowercased(), balance: values[id].description)
            balances.append(balance)
          }
          BalanceStorage.shared.setBalances(balances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        } else {
          print("[LoadBalanceCoordinator] load error not equal count")
        }
      case .failure(let error):
        print("[LoadBalanceCoordinator] load error \(error.description)")
      }
    }
  }

  func loadTokenBalancesFromApi(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getBalances(address: self.session.wallet.address.description, forceSync: forceSync)) { (result) in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(BalancesResponse.self, from: resp.data)
          let balances = data.balances.map { (data) -> TokenBalance in
            return TokenBalance(address: data.token.address, balance: data.balance)
          }
          let tokens = data.balances.map { data -> Token in
            return data.token
          }
          BalanceStorage.shared.setBalances(balances)
          KNSupportedTokenStorage.shared.updateNewDataForCustomTokensIfHave(tokens)
          KNSupportedTokenStorage.shared.checkAddCustomTokenIfNeeded(tokens)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          completion(true)
        } catch let error {
          print("[LoadBalance] \(error.localizedDescription)")
          completion(false)
        }
      case .failure(let error):
        print("[LoadBalance] \(error.localizedDescription)")
        completion(false)
      }
    }
  }

  func loadTotalBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getTotalBalance(address: self.session.wallet.address.description, forceSync: forceSync, KNEnvironment.allChainPath)) { (result) in
      if case .success(let resp) = result, let json = try? resp.mapJSON() as? JSONDictionary ?? [:], let data = json["data"] as? JSONDictionary, let balances = data["balances"] as? [JSONDictionary] {
        var summaryChains: [KNSummaryChainModel] = []
        for item in balances {
          let summaryChainModel = KNSummaryChainModel(json: item)
          summaryChains.append(summaryChainModel)
        }
        BalanceStorage.shared.saveSummaryChainModels(summaryChains)
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        completion(true)
      } else {
        var summaryChains: [KNSummaryChainModel] = []
        if KNEnvironment.default == .ropsten {
          summaryChains = [KNSummaryChainModel.defaultValue(chainId: Constants.ethRoptenPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.bscRoptenPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.polygonRoptenPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.avalancheRoptenPRC.chainID)]
        } else {
          summaryChains = [KNSummaryChainModel.defaultValue(chainId: Constants.ethMainnetPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.bscMainnetPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.polygonMainnetPRC.chainID),
                           KNSummaryChainModel.defaultValue(chainId: Constants.avalancheMainnetPRC.chainID)]
        }
        BalanceStorage.shared.saveSummaryChainModels(summaryChains)
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        completion(false)
      }
    }
  }

  func loadNFTBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getNTFBalance(address: self.session.wallet.address.description, forceSync: forceSync)) { result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(NftResponse.self, from: resp.data)
          print("[LoadNFT] \(data)")
          BalanceStorage.shared.setNFTBalance(data.balances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          completion(true)
        } catch let error {
          print("[LoadNFT] \(error.localizedDescription)")
          completion(false)
        }
      case .failure(let error):
        print("[LoadNFT] \(error.localizedDescription)")
        completion(false)
      }
    }
  }

  func loadLendingBalances(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.request(.getLendingBalance(address: self.session.wallet.address.description, forceSync: forceSync)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["result"] as? [JSONDictionary] {
        var balances: [LendingPlatformBalance] = []
        result.forEach { (element) in
          var lendingBalances: [LendingBalance] = []
          if let lendingBalancesDicts = element["balances"] as? [JSONDictionary] {
            lendingBalancesDicts.forEach { (item) in
              lendingBalances.append(LendingBalance(dictionary: item))
            }
          }
          let platformBalance = LendingPlatformBalance(name: element["name"] as? String ?? "", balances: lendingBalances)
          balances.append(platformBalance)
        }
        BalanceStorage.shared.setLendingBalances(balances)
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        completion(true)
      } else {
        if KNEnvironment.default == .ropsten { return }
        self.loadLendingBalances(completion: completion)
      }
    }
  }

  func loadLendingDistributionBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    guard !KNGeneralProvider.shared.lendingDistributionPlatform.isEmpty else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])

    provider.request(.getLendingDistributionBalance(lendingPlatform: KNGeneralProvider.shared.lendingDistributionPlatform, address: self.session.wallet.address.description, forceSync: forceSync)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["balance"] as? JSONDictionary {
        let balance = LendingDistributionBalance(dictionary: result)
        BalanceStorage.shared.setLendingDistributionBalance(balance)
        completion(true)
      } else {
        if KNEnvironment.default == .ropsten { return }
        self.loadLendingDistributionBalance(completion: completion)
      }
    }
  }

  func loadLiquidityPool(forceSync: Bool = false, completion:  @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = self.session.wallet.address.description
    let chain = KNGeneralProvider.shared.chainName
    provider.request(.getLiquidityPool(address: address, chain: chain, forceSync: forceSync)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let balances = json["balances"] as? [JSONDictionary] {
        var poolArray: [LiquidityPoolModel] = []
        for item in balances {
          if let poolJSON = item["token"] as? JSONDictionary, let tokensJSON = item["underlying"] as? [JSONDictionary], let project = item["project"] as? String {
            let lpmodel = LiquidityPoolModel(poolJSON: poolJSON, tokensJSON: tokensJSON)
            lpmodel.project = project
            poolArray.append(lpmodel)
          }
        }
        BalanceStorage.shared.setLiquidityPools(poolArray)
        completion(true)
      } else {
        completion(false)
      }
    }
  }

  func loadCustomNFTBalane(completion: @escaping (Bool) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }

    let group = DispatchGroup()
    let customSection = BalanceStorage.shared.getCustomNFT()

    customSection.forEach { sectionItem in
      sectionItem.items.forEach { nftItem in
        group.enter()
        KNGeneralProvider.shared.getSupportInterface(address: sectionItem.collectibleAddress) { interfaceResult in
          switch interfaceResult {
          case .success(let erc721):
            if erc721 {
              KNGeneralProvider.shared.getOwnerOf(address: sectionItem.collectibleAddress, id: nftItem.tokenID) { ownerResult in
                switch ownerResult {
                case .success(let owner):
                  if owner.lowercased() == self.session.wallet.address.description.lowercased() {
                    //do nothing
                  } else {
                    BalanceStorage.shared.removeCustomNFT(categoryAddress: sectionItem.collectibleAddress, itemID: nftItem.tokenID)
                  }
                default:
                  break
                }
                group.leave()
              }
            } else {
              provider.getNFTBalance(for: sectionItem.collectibleAddress, id: nftItem.tokenID) { result in
                switch result {
                case .success(let bigInt):
                  let balance = Balance(value: bigInt)
                  if balance.isZero {
                    BalanceStorage.shared.removeCustomNFT(categoryAddress: sectionItem.collectibleAddress, itemID: nftItem.tokenID)
                  } else {
                    BalanceStorage.shared.updateCustomNFTBalance(categoryAddress: sectionItem.collectibleAddress, itemID: nftItem.tokenID, balance: bigInt.description)
                  }
                default:
                  break
                }
                group.leave()
              }
            }
          case .failure(_):
            group.leave()
          }
        }
      }
    }
    group.notify(queue: .main) {
      BalanceStorage.shared.saveCustomNFT()
      KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
      completion(true)
    }
  }
}

extension KNLoadBalanceCoordinator {
  func appCoordinatorRefreshData(mode: ViewMode, overviewMode: OverviewMode) {
    if overviewMode == .summary {
      self.loadTotalBalance(forceSync: true) { _ in
        KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
      }
    } else {
      switch mode {
      case .asset:
        self.loadTokenBalancesFromApi(forceSync: true) { _ in
          KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
        }
      case .showLiquidityPool:
        self.loadLiquidityPool(forceSync: true) { _ in
          KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
        }
      case .supply:
        let group = DispatchGroup()
        group.enter()
        self.loadLendingBalances(forceSync: true) { _ in
          group.leave()
        }

        group.enter()
        self.loadLendingDistributionBalance(forceSync: true) { _ in
          group.leave()
        }

        group.notify(queue: .global()) {
          KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
        }
      case .nft:
        self.loadNFTBalance(forceSync: true) { _ in
          KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
        }
      default:
        return
      }
    }
  }
}

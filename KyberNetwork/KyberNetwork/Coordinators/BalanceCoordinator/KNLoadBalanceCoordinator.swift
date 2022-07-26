// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import Moya
import Sentry
import FirebasePerformance
import Firebase
import KrystalWallets

class KNLoadBalanceCoordinator {

//  fileprivate var session: KNSession! //TODO: use general provider to load balance instead of external provider

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false

  var otherTokensBalance: [String: Balance] = [:]

  fileprivate var fetchBalanceTimer: Timer?
  fileprivate var fetchTotalBalanceTimer: Timer?
  fileprivate var fetchTokenBalanceTimer: Timer?
  fileprivate var isFetchNonSupportedBalance: Bool = false

  fileprivate var lastRefreshTime: Date = Date()

  var address: KAddress {
    return AppDelegate.session.address
  }
  
  var tokenStorage: KNTokenStorage {
    return AppDelegate.session.tokenStorage
  }
  
  deinit {
    self.exit()
  }

  func restartNewSession(_ session: KNSession) {
//    self.session = session
//    self.resume()
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
    let span3 = tx.startChild(operation: "load-nft-balances")
    self.loadNFTBalance { success in
      span3.finish()
      group.leave()
    }
    
    group.enter()
    let span4 = tx.startChild(operation: "load-custom-nft-balances")
    self.loadCustomNFTBalane { success in
      span4.finish()
      group.leave()
    }

    group.enter()
    let span5 = tx.startChild(operation: "load-liquidity-pool")
    self.loadLiquidityPool { success in
      span5.finish()
      group.leave()
    }

    group.enter()
    let span6 = tx.startChild(operation: "load-total-balance")
    self.loadTotalBalance { success in
      span6.finish()
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
    
    fetchTokenBalanceTimer?.invalidate()
    fetchTokenBalanceTimer = Timer.scheduledTimer(
      withTimeInterval: KNLoadingInterval.seconds15,
      repeats: true,
      block: { [weak self] timer in
        self?.loadTokenBalancesFromApi(completion: { _ in
        })
      }
    )
    self.loadTokenBalancesFromApi(completion: { _ in
    })
    
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

    fetchTokenBalanceTimer?.invalidate()
    fetchTokenBalanceTimer = nil

    fetchTotalBalanceTimer?.invalidate()
    fetchTotalBalanceTimer = nil
  }

  func exit() {
    pause()
  }

  fileprivate func fetchTokenBalances(tokens: [String], completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard let provider = AppDelegate.session.externalProvider else {
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
            self.tokenStorage.updateBalance(for: tokens[id], balance: values[id])
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
    let tokens = KNSupportedTokenStorage.shared.getSupportedTokens().map(\.address)
//    var erc20Address: [Address] = []
//    tokens.forEach { (token) in
//      if let address = Address(string: token.address) {
//        erc20Address.append(address)
//      }
//    }
    
    guard !tokens.isEmpty else {
      return
    }
    let address = AppDelegate.session.address.addressString
    KNGeneralProvider.shared.getMutipleERC20Balances(for: address, tokens: tokens) { result in
      switch result {
      case .success(let values):
        if values.count == tokens.count {
          var balances: [TokenBalance] = []
          for id in 0..<values.count {
            let balance = TokenBalance(address: tokens[id].lowercased(), balance: values[id].description)
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
    provider.requestWithFilter(.getBalances(address: AppDelegate.session.address.addressString, forceSync: forceSync)) { (result) in
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
    let addresses = AppDelegate.session.getCurrentWalletAddresses().map(\.addressString)
    provider.requestWithFilter(.getTotalBalance(address: addresses, forceSync: forceSync, KNEnvironment.allChainPath)) { (result) in
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
        let summaryChains = ChainType.getAllChain().map { chain in
          KNSummaryChainModel.defaultValue(chainId: chain.getChainId())
        }
        BalanceStorage.shared.saveSummaryChainModels(summaryChains)
        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
        completion(false)
      }
    }
  }

  func loadNFTBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = AppDelegate.session.address.addressString
    provider.requestWithFilter(.getAllNftBalance(address: address, chains: [])) { result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(AllNftResponse.self, from: resp.data)
          print("[LoadNFT] \(data)")
          
          var allBalances: [NFTSection] = []
          
          data.data.forEach { e in
            let chain = ChainType.getChain(id: e.chainID)
            e.balances.forEach { bal in
              bal.chainType = chain
            }
            allBalances.append(contentsOf: e.balances)
          }
          
          BalanceStorage.shared.setNFTBalance(allBalances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          completion(true)
        } catch let error {
          completion(false)
        }
      case .failure(let error):
        completion(false)
      }
    }
  }

  func loadLendingBalances(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    guard KNGeneralProvider.shared.currentChain.isSupportSwap() else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    provider.requestWithFilter(.getAllLendingBalance(address: AppDelegate.session.address.addressString, chains: [])) { (result) in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(AllLendingBalanceResponse.self, from: response.data)
          print(data.data)
          
          var balances: [LendingPlatformBalance] = []
          
          data.data.forEach { e in
            if let chain = ChainType.getChain(id: e.chainID) {
              let lendingBalances = e.balances
              lendingBalances.forEach { bal in
                bal.chainType = chain
              }
              balances.append(contentsOf: lendingBalances)
            }
          }
//          print(balances)
          BalanceStorage.shared.setLendingBalances(balances)
//          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          completion(true)
        } catch let error {
          print(error.localizedDescription)
        }
        
      case .failure(let error):
        completion(false)
      }
      
//      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["result"] as? [JSONDictionary] {
//        var balances: [LendingPlatformBalance] = []
//        result.forEach { (element) in
//          var lendingBalances: [LendingBalance] = []
//          if let lendingBalancesDicts = element["balances"] as? [JSONDictionary] {
//            lendingBalancesDicts.forEach { (item) in
//              lendingBalances.append(LendingBalance(dictionary: item))
//            }
//          }
//          let platformBalance = LendingPlatformBalance(name: element["name"] as? String ?? "", balances: lendingBalances)
//          balances.append(platformBalance)
//        }
//        BalanceStorage.shared.setLendingBalances(balances)
//        KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
//        completion(true)
//      } else {
//        if KNEnvironment.default != .production { return }
//        self.loadLendingBalances(completion: completion)
//      }
    }
  }

  func loadLendingDistributionBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    guard !KNGeneralProvider.shared.lendingDistributionPlatform.isEmpty else { return }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])

    provider.requestWithFilter(.getLendingDistributionBalance(lendingPlatform: KNGeneralProvider.shared.lendingDistributionPlatform, address: address.addressString, forceSync: forceSync)) { (result) in
      if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:], let result = json["balance"] as? JSONDictionary {
        let balance = LendingDistributionBalance(dictionary: result)
        BalanceStorage.shared.setLendingDistributionBalance(balance)
        completion(true)
      } else {
        if KNEnvironment.default != .production { return }
        self.loadLendingDistributionBalance(completion: completion)
      }
    }
  }

  func loadLiquidityPool(forceSync: Bool = false, completion:  @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    let address = AppDelegate.session.address.addressString
    let chain = KNGeneralProvider.shared.chainName
    provider.requestWithFilter(.getLiquidityPool(address: address, chain: chain, forceSync: forceSync)) { (result) in
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
    guard let provider = AppDelegate.session.externalProvider else {
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
                  if owner != self.address.addressString {
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
      let group = DispatchGroup()
      group.enter()
      self.loadTotalBalance(forceSync: true) { _ in
        group.leave()
      }

      switch mode {
      case .asset:
        group.enter()
        self.loadTokenBalancesFromApi(forceSync: true) { _ in
          group.leave()
        }
      case .showLiquidityPool:
        group.enter()
        self.loadLiquidityPool(forceSync: true) { _ in
          group.leave()
        }
      case .supply:
        group.enter()
        self.loadLendingBalances(forceSync: true) { _ in
          group.leave()
        }

        group.enter()
        self.loadLendingDistributionBalance(forceSync: true) { _ in
          group.leave()
        }
      case .nft:
        group.enter()
        self.loadNFTBalance(forceSync: true) { _ in
          group.leave()
        }
      default:
        break
      }
      group.notify(queue: .global()) {
        KNNotificationUtil.postNotification(for: kPullToRefreshNotificationKey)
      }
    }
  }
}

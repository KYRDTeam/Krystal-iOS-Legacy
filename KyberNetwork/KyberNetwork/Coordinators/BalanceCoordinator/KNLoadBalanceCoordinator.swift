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
import AppState

protocol KNLoadBalanceCoordinatorDelegate: class {
  func loadBalanceCoordinatorDidGetBalance(chainBalances: [ChainBalanceModel])
  func loadBalanceCoordinatorDidGetLP(chainLP: [ChainLiquidityPoolModel])
}
class KNLoadBalanceCoordinator {

//  fileprivate var session: KNSession! //TODO: use general provider to load balance instead of external provider

  fileprivate var fetchOtherTokensBalanceTimer: Timer?
  fileprivate var isFetchingOtherTokensBalance: Bool = false

  var otherTokensBalance: [String: Balance] = [:]

  fileprivate var fetchBalanceTimer: Timer?
  fileprivate var fetchTotalBalanceTimer: Timer?
  fileprivate var fetchTokenBalanceTimer: Timer?
  fileprivate var isFetchNonSupportedBalance: Bool = false
  weak var delegate: KNLoadBalanceCoordinatorDelegate?
  fileprivate var lastRefreshTime: Date = Date()
    
    var currentWalletAddresses: [KAddress] {
        let currentAddress = AppState.shared.currentAddress
        if currentAddress.isWatchWallet {
            return [currentAddress]
        }
        return WalletManager.shared.getAllAddresses(walletID: currentAddress.walletID)
    }
  
  var tokenStorage: KNTokenStorage {
    return AppDelegate.session.tokenStorage
  }
  
  deinit {
    self.exit()
  }

  func restartNewSession(_ session: KNSession) {
//    self.session = session
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
      DispatchQueue.main.async {
        AppDelegate.shared.window?.rootViewController?.hideLoading()
      }
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
    provider.getMultipleERC20Balances(address: AppState.shared.currentAddress, tokens) { [weak self] result in
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
      let address = AppState.shared.currentAddress.addressString
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
    let provider = MoyaProvider<KrytalService>(plugins: [])
    var addressString: [String] = []
    let currentAddress = AppState.shared.currentAddress
    if currentAddress.addressType == .evm {
      addressString.append("ethereum:\(currentAddress.addressString)")
    } else {
      addressString.append("solana:\(currentAddress.addressString)")
    }
    var quoteSymbols = ["btc","usd"]
    var chainIds = ["\(KNGeneralProvider.shared.currentChain.getChainId())"]
    
    if AppState.shared.isSelectedAllChain {
      chainIds = ChainType.getAllChain().map {
        return "\($0.getChainId())"
      }
      addressString = currentWalletAddresses.map { address -> String in
        if address.addressType == .evm {
          return "ethereum:\(address.addressString)"
        } else {
          return "solana:\(address.addressString)"
        }
      }
    } else {
      quoteSymbols.append("\(KNGeneralProvider.shared.currentChain.quoteToken().lowercased())")
    }
    
    provider.requestWithFilter(.getMultichainBalance(address: addressString, chainIds: chainIds, quoteSymbols: quoteSymbols)) { (result) in
      switch result {
      case .success(let resp):
        var chainBalanceModels: [ChainBalanceModel] = []
        if let responseJson = try? resp.mapJSON() as? JSONDictionary ?? [:], let jsons = responseJson["data"] as? [JSONDictionary] {
          var allTokens: [Token] = []
          var tokenBalances: [TokenBalance] = []
          jsons.forEach { jsonData in
            let chainModel = ChainBalanceModel(json: jsonData)
            chainBalanceModels.append(chainModel)
            let newTokenBalances = chainModel.balances.map { TokenBalance(address: $0.token.address, balance: $0.balance) }
            if chainModel.chainId == KNGeneralProvider.shared.currentChain.getChainId() {
                allTokens.append(contentsOf: chainModel.balances.map(\.token))
                tokenBalances.append(contentsOf: newTokenBalances)
            } else if let chain = ChainType.make(chainID: chainModel.chainId) {
                BalanceStorage.shared.setCacheForChain(chain: chain, balances: newTokenBalances)
            }
          }
          BalanceStorage.shared.setBalances(tokenBalances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          self.delegate?.loadBalanceCoordinatorDidGetBalance(chainBalances: chainBalanceModels)
        }
        completion(true)
      case .failure:
        completion(false)
      }
    }
  }

  func loadTotalBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [])
    let addresses = currentWalletAddresses.map(\.addressString)
    provider.requestWithFilter(.getTotalBalance(address: addresses, forceSync: forceSync, KNEnvironment.allChainIds)) { (result) in
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
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    let address = AppState.shared.currentAddress.addressString
    var chainIds = ["\(KNGeneralProvider.shared.currentChain.getChainId())"]
    
    if AppState.shared.isSelectedAllChain {
      chainIds = ChainType.getAllChain().map {
        return "\($0.getChainId())"
      }
    }
    provider.requestWithFilter(.getAllNftBalance(address: address, chains: chainIds)) { result in
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
    guard KNGeneralProvider.shared.currentChain.isSupportSwap() else {
      completion(false)
      return
    }
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    var chainIds = ["\(KNGeneralProvider.shared.currentChain.getChainId())"]
    
    if AppState.shared.isSelectedAllChain {
      chainIds = ChainType.getAllChain().map {
        return "\($0.getChainId())"
      }
    }
    provider.requestWithFilter(.getAllLendingBalance(address: AppState.shared.currentAddress.addressString, chains: chainIds, quotes: [])) { (result) in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(AllLendingBalanceResponse.self, from: response.data)
          print(data.data)
          
          var balances: [LendingPlatformBalance] = []
          
          data.data.forEach { e in
            if let chain = ChainType.getChain(id: e.chainID) {
              let lendingBalances = e.balances ?? []
              lendingBalances.forEach { bal in
                bal.chainType = chain
              }
              balances.append(contentsOf: lendingBalances)
            }
          }

          BalanceStorage.shared.setLendingBalances(balances)
          KNNotificationUtil.postNotification(for: kOtherBalanceDidUpdateNotificationKey)
          completion(true)
        } catch let error {
          print(error.localizedDescription)
          completion(false)
        }
      case .failure( _):
        completion(false)
      }
    }
  }

  func loadLendingDistributionBalance(forceSync: Bool = false, completion: @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    var chainIds = ["\(KNGeneralProvider.shared.currentChain.getChainId())"]
    
    if AppState.shared.isSelectedAllChain {
      chainIds = ChainType.getAllChain().map {
        return "\($0.getChainId())"
      }
    }
    provider.requestWithFilter(.getAllLendingDistributionBalance(lendingPlatforms: ChainType.allLendingDistributionPlatform(), address: AppState.shared.currentAddress.addressString, chains: chainIds, quotes: [])) { result in
      switch result {
      case .success(let response):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(AllLendingDistributionBalanceResponse.self, from: response.data)
          var result: [LendingDistributionBalance] = []
          data.data.forEach { d in
            if let chain = ChainType.getChain(id: d.chainID) {
              d.balances?.forEach({ e in
                e.chainType = chain
                result.append(e)
              })
            }
          }
          BalanceStorage.shared.setLendingDistributionBalance(result)
          completion(true)
        } catch let error {
          print(error.localizedDescription)
          completion(false)
        }
      case .failure( _):
        completion(false)
      }
    }
  }

  func loadLiquidityPool(forceSync: Bool = false, completion:  @escaping (Bool) -> Void) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    let addressString:[String] = [AppState.shared.currentAddress.addressString]
    var quoteSymbols = ["btc","usd"]
    var chainIds = ["\(KNGeneralProvider.shared.currentChain.getChainId())"]
    
    if AppState.shared.isSelectedAllChain {
      quoteSymbols.append("\(KNGeneralProvider.shared.currentChain.quoteToken().lowercased())")
      chainIds = ChainType.getAllChain().map {
        return "\($0.getChainId())"
      }
    }
    provider.requestWithFilter(.getLiquidityPool(address: addressString, chainIds: chainIds, quoteSymbols: quoteSymbols)) { (result) in
      var chainLiquidityPoolModels: [ChainLiquidityPoolModel] = []
      switch result {
      case .success(let resp):
        if let responseJson = try? resp.mapJSON() as? JSONDictionary ?? [:], let jsons = responseJson["data"] as? [JSONDictionary] {
          jsons.forEach { jsonData in
            let chainModel = ChainLiquidityPoolModel(json: jsonData)
            chainLiquidityPoolModels.append(chainModel)
          }
        }
        self.delegate?.loadBalanceCoordinatorDidGetLP(chainLP: chainLiquidityPoolModels)
        completion(true)
      case .failure(let error):
        self.delegate?.loadBalanceCoordinatorDidGetLP(chainLP: chainLiquidityPoolModels)
        completion(false)
      }
    }
  }

  func loadCustomNFTBalane(completion: @escaping (Bool) -> Void) {
    guard let provider = AppDelegate.session.externalProvider else {
      completion(false)
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
                    if owner != AppState.shared.currentAddress.addressString {
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
  func refreshMultiChainData(mode: ViewMode) {
    
  }
  
  func refreshSingleChainData(mode: ViewMode) {
    
  }
  
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

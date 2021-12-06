// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result

/*
 Handling notification from many fetchers, views, ...
 */
extension KNAppCoordinator {
  func addObserveNotificationFromSession() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.transactionStateDidUpdate(_:)),
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    let tokenBalanceName = Notification.Name(kOtherBalanceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenBalancesDidUpdateNotification(_:)),
      name: tokenBalanceName,
      object: nil
    )
    let tokenTxListName = Notification.Name(kTokenTransactionListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenTransactionListDidUpdate(_:)),
      name: tokenTxListName,
      object: nil
    )
    let tokenObjectListName = Notification.Name(kTokenObjectListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: tokenObjectListName,
      object: nil
    )
    let openExchangeName = Notification.Name(kOpenExchangeTokenViewKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.openExchangeTokenView(_:)),
      name: openExchangeName,
      object: nil
    )

    let newRecevieName = Notification.Name(kNewReceivedTransactionKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.handleNewReceiveTx(_:)),
      name: newRecevieName,
      object: nil
    )
  }

  func addInternalObserveNotification() {
    let pullToRefresh = Notification.Name(kPullToRefreshNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(pullToRefreshDone),
      name: pullToRefresh,
      object: nil
    )

    let changeChain = Notification.Name(kChangeChainNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.chainDidUpdateNotification(_:)),
      name: changeChain,
      object: nil
    )

    let rateTokensName = Notification.Name(kExchangeTokenRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateTokenDidUpdateNotification(_:)),
      name: rateTokensName,
      object: nil)

    let rateUSDName = Notification.Name(kExchangeUSDRateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.exchangeRateUSDDidUpdateNotification(_:)),
      name: rateUSDName,
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.tokenObjectListDidUpdate(_:)),
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.gasPriceCachedDidUpdate(_:)),
      name: gasPriceName,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userRestoreIdReceived),
      name: NSNotification.Name(rawValue: FRESHCHAT_USER_RESTORE_ID_GENERATED),
      object: nil
    )
  }

  func removeObserveNotificationFromSession() {
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTransactionDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOtherBalanceDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenTransactionListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kTokenObjectListDidUpdateNotificationKey),
      object: nil
    )
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kOpenExchangeTokenViewKey),
      object: nil
    )
  }

  func removeInternalObserveNotification() {
    
    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kPullToRefreshNotificationKey),
      object: nil
    )

    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeTokenRateNotificationKey),
      object: nil
    )

    NotificationCenter.default.removeObserver(
      self,
      name: Notification.Name(kExchangeUSDRateNotificationKey),
      object: nil
    )
    let supportedTokensName = Notification.Name(kSupportedTokenListDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: supportedTokensName,
      object: nil
    )
    let gasPriceName = Notification.Name(kGasPriceDidUpdateNotificationKey)
    NotificationCenter.default.removeObserver(
      self,
      name: gasPriceName,
      object: nil
    )
    let marketDataName = Notification.Name(kMarketSuccessToLoadNotiKey)
    NotificationCenter.default.removeObserver(
      self,
      name: marketDataName,
      object: nil
    )

    let liveChatName = Notification.Name(FRESHCHAT_USER_RESTORE_ID_GENERATED)
    NotificationCenter.default.removeObserver(
      self,
      name: liveChatName,
      object: nil
    )
  }

  @objc func exchangeRateTokenDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }

//    self.balanceTabCoordinator?.appCoordinatorExchangeRateDidUpdate(
//      totalBalanceInUSD: loadBalanceCoordinator.totalBalanceInUSD,
//      totalBalanceInETH: loadBalanceCoordinator.totalBalanceInETH
//    )
  }

//  @objc func prodCachedRateTokenDidUpdateNotification(_ sender: Any?) {
//    if self.session == nil { return }
//    self.exchangeCoordinator?.appCoordinatorUpdateExchangeTokenRates()
//    self.limitOrderCoordinator?.appCoordinatorUpdateExchangeTokenRates()
//  }

  @objc func exchangeRateUSDDidUpdateNotification(_ sender: Notification) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = BigInt(0)
    let totalETH: BigInt = BigInt(0)

    self.exchangeCoordinator?.appCoordinatorUSDRateDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH
    )

    self.settingsCoordinator?.appCoordinatorUSDRateUpdate()
  }
  
  @objc func chainDidUpdateNotification(_ sender: Notification) {
    if let address = sender.object as? String, let wal = self.session.keystore.wallets.first(where: { $0.address.description.lowercased() == address.lowercased() }) {
      self.restartNewSession(wal)
    }

    KNSupportedTokenCoordinator.shared.pause()
    KNSupportedTokenCoordinator.shared.resume()
    KNSupportedTokenStorage.shared.reloadData()
    
    KNRateCoordinator.shared.pause()
    KNRateCoordinator.shared.resume()
    KNTrackerRateStorage.shared.reloadData()
    
    KNGasCoordinator.shared.pause()
    KNGasCoordinator.shared.resume()
    
    self.exchangeCoordinator?.appCoordinatorDidUpdateChain()
    self.overviewTabCoordinator?.appCoordinatorDidUpdateChain()
    self.investCoordinator?.appCoordinatorDidUpdateChain()
    self.earnCoordinator?.appCoordinatorDidUpdateChain()
    self.settingsCoordinator?.appCoordinatorDidUpdateChain()
    self.session.externalProvider?.minTxCount = 0
    
  }

  @objc func tokenBalancesDidUpdateNotification(_ sender: Any?) {
    if self.session == nil { return }
    guard let loadBalanceCoordinator = self.loadBalanceCoordinator else { return }
    let totalUSD: BigInt = BigInt(0)
    let totalETH: BigInt = BigInt(0)
    let otherTokensBalance: [String: Balance] = loadBalanceCoordinator.otherTokensBalance

    self.exchangeCoordinator?.appCoordinatorTokenBalancesDidUpdate(
      totalBalanceInUSD: totalUSD,
      totalBalanceInETH: totalETH,
      otherTokensBalance: otherTokensBalance
    )

    self.settingsCoordinator?.appCoordinatorTokenBalancesDidUpdate(balances: otherTokensBalance)
    
    self.earnCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.investCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.overviewTabCoordinator?.appCoordinatorDidUpdateTokenList()
  }

  //swiftlint:disable function_body_length
  @objc func transactionStateDidUpdate(_ sender: Notification) {
    guard self.session != nil, let transaction = sender.object as? InternalHistoryTransaction else { return }
    
    self.exchangeCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.earnCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.investCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.settingsCoordinator?.appCoordinatorPendingTransactionsDidUpdate()

    let updateOverview = self.overviewTabCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateExchange = self.exchangeCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateEarn = self.earnCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateInvest = self.investCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    if !(updateOverview || updateExchange || updateEarn || updateInvest) {
      guard transaction.chain == KNGeneralProvider.shared.currentChain else {
        return
      }
      if transaction.state == .done {
        self.loadBalanceCoordinator?.loadAllBalances()
        self.navigationController.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: "Transaction is successful",
          time: 3
        )
      } else if transaction.state == .drop || transaction.state == .error {
        self.navigationController.showErrorTopBannerMessage(
        with: NSLocalizedString("failed", value: "Failed", comment: ""),
        message: "Transaction is failure",
        time: 3
        )
      }
    }

    if transaction.state == .done || transaction.state == .drop || transaction.state == .error {
      self.loadBalanceCoordinator?.loadAllBalances()
      self.session.transacionCoordinator?.loadEtherscanTransactions()
    }
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.overviewTabCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.earnCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.investCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.exchangeCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
    self.settingsCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)
  }

  @objc func gasPriceCachedDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.exchangeCoordinator?.appCoordinatorGasPriceCachedDidUpdate()
  }

  @objc func openExchangeTokenView(_ sender: Any?) {
    if self.session == nil { return }
    self.tabbarController.selectedIndex = 1
    self.exchangeCoordinator?.navigationController.popToRootViewController(animated: true)
  }

  @objc func userRestoreIdReceived() {
    guard let restoreId = FreshchatUser.sharedInstance().restoreID, let externalID = FreshchatUser.sharedInstance().externalID  else {
      return
    }
    if var saved = UserDefaults.standard.object(forKey: KNAppTracker.kSavedRestoreIDForLiveChat) as? [String: String] {
      saved[externalID] = restoreId
      UserDefaults.standard.set(saved, forKey: KNAppTracker.kSavedRestoreIDForLiveChat)
    } else {
      let dict = [externalID: restoreId]
      UserDefaults.standard.set(dict, forKey: KNAppTracker.kSavedRestoreIDForLiveChat)
    }
    Freshchat.sharedInstance().identifyUser(withExternalID: externalID, restoreID: restoreId)
  }
  
  @objc func handleNewReceiveTx(_ sender: Notification) {
    guard let transaction = sender.object as? HistoryTransaction else { return }
    
    if transaction.type == .receiveETH {
      if let internalTx = transaction.transacton.first, let amount = BigInt(internalTx.value) {
        let message = "You have received \(amount.shortString(decimals: 18)) ETH from \(internalTx.from)"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
    
    if transaction.type == .receiveToken {
      if let tokenTx = transaction.tokenTransactions.first, let amount = BigInt(tokenTx.value), let decimals = Int(tokenTx.tokenDecimal) {
        let message = "You have received \(amount.shortString(decimals: decimals)) \(tokenTx.tokenSymbol) from \(tokenTx.from)"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
    
    if transaction.type == .earn {
      let tokenTx = transaction.tokenTransactions.first { (tx) -> Bool in
        let address = self.session.wallet.address
        return tx.to.lowercased() == address.description.lowercased()
      }

      if let unwrapped = tokenTx, let amount = BigInt(unwrapped.value), let decimals = Int(unwrapped.tokenDecimal) {
        let message = "You have received \(amount.shortString(decimals: decimals)) \(unwrapped.tokenSymbol) from Suppying"
        self.tabbarController.showTopBannerView(message: message)
      }
    }
  }
  
  @objc func pullToRefreshDone() {
    self.overviewTabCoordinator?.appCoordinatorPullToRefreshDone()
  }
}

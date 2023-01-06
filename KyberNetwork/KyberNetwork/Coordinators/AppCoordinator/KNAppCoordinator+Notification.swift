// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import Result
import KrystalWallets
import AppState
import Dependencies

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
        selector: #selector(handleAppSwitchAddressNotification),
        name: .appAddressChanged,
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
      
      NotificationCenter.default.removeObserver(
        self,
        name: .appAddressChanged,
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

    self.settingsCoordinator?.appCoordinatorUSDRateUpdate()
  }
  
  @objc func chainDidUpdateNotification(_ notification: Notification) {
    let currentAddress = session.address
    let targetAddressType = KNGeneralProvider.shared.currentChain.addressType
    
    if targetAddressType == currentAddress.addressType {
      // Do nothing
    } else if let address = walletManager.getAllAddresses(walletID: currentAddress.walletID, addressType: targetAddressType).first {
      restartSession(address: address)
    } else if let address = walletManager.getAllAddresses(addressType: targetAddressType).first {
      restartSession(address: address)
    }
    KNSupportedTokenCoordinator.shared.pause()
    KNSupportedTokenCoordinator.shared.resume()
    KNSupportedTokenStorage.shared.reloadData()
    self.isFirstUpdateChain = KNSupportedTokenStorage.shared.allActiveTokens.isEmpty

    KNRateCoordinator.shared.pause()
    KNRateCoordinator.shared.resume()
    KNTrackerRateStorage.shared.reloadData()
    
    if KNGeneralProvider.shared.currentChain == .solana {
      SolFeeCoordinator.shared.resume()
    } else {
      KNGasCoordinator.shared.pause()
      KNGasCoordinator.shared.resume()
    }
    
    self.overviewTabCoordinator?.appCoordinatorDidUpdateChain()
    self.investCoordinator?.appCoordinatorDidUpdateChain()
    self.loadBalanceCoordinator?.loadLendingBalances(completion: { _ in
    })
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

    self.settingsCoordinator?.appCoordinatorTokenBalancesDidUpdate(balances: otherTokensBalance)
      
    self.earnCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.investCoordinator?.appCoordinatorTokenBalancesDidUpdate(totalBalanceInUSD: totalUSD, totalBalanceInETH: totalETH, otherTokensBalance: otherTokensBalance)
    
    self.overviewTabCoordinator?.appCoordinatorDidUpdateTokenList()
  }

  //swiftlint:disable function_body_length
  @objc func transactionStateDidUpdate(_ sender: Notification) {
    guard self.session != nil, let transaction = sender.object as? InternalHistoryTransaction else { return }

    self.overviewTabCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.investCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.settingsCoordinator?.appCoordinatorPendingTransactionsDidUpdate()
    self.earnCoordinator?.appCoordinatorPendingTransactionsDidUpdate()

    let updateOverview = self.overviewTabCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateInvest = self.investCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false
    let updateEarn = self.earnCoordinator?.appCoordinatorUpdateTransaction(transaction) ?? false

    if !(updateOverview || updateEarn || updateInvest) {
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
      self.session.transactionCoordinator?.loadEtherscanTransactions()
    }
  }

  @objc func tokenTransactionListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    self.overviewTabCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.earnCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
    self.investCoordinator?.appCoordinatorTokensTransactionsDidUpdate()
  }

  @objc func tokenObjectListDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
    let tokenObjects: [TokenObject] = self.session.tokenStorage.tokens
    self.settingsCoordinator?.appCoordinatorTokenObjectListDidUpdate(tokenObjects)

    if self.isFirstUpdateChain {
      self.isFirstUpdateChain = false
      KNRateCoordinator.shared.pause()
      KNRateCoordinator.shared.resume()
      KNTrackerRateStorage.shared.reloadData()
    }
  }

  @objc func gasPriceCachedDidUpdate(_ sender: Any?) {
    if self.session == nil { return }
  }

  @objc func openExchangeTokenView(_ sender: Any?) {
    if self.session == nil { return }
    AppDependencies.router.openSwap()
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
        return tx.to == self.session.address.addressString
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
    
    @objc func handleAppSwitchAddressNotification(notification: Notification) {
        let address = AppState.shared.currentAddress
        if !AppState.shared.isBrowsingMode {
            restartSession(address: address)
        }
    }
}

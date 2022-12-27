//
//  SwapV2Coordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/08/2022.
//

import Foundation
import UIKit
import KrystalWallets
import BigInt
import Utilities
import AppState
import Dependencies
import BaseModule
import Services
import TransactionModule

public class SwapCoordinator: NSObject, Coordinator {
    public var coordinators: [Coordinator] = []
    var rootViewController: SwapV2ViewController!
    public var navigationController: UINavigationController!
    
    var historyCoordinator: Coordinator?
    private let swapRepository = SwapRepository()
    
    public func start() {
        let vc = SwapV2ViewController.instantiateFromNib()
        let viewModel = SwapV2ViewModel(
            actions: SwapV2ViewModelActions(
                onSelectOpenHistory: {
                    self.openTransactionHistory()
                },
                openSwapConfirm: { swapObject, quoteToken in
                    self.openSwapConfirm(object: swapObject, quoteToken: quoteToken)
                },
                openApprove: { tokenObject, amount in
                    self.openApprove(token: tokenObject, amount: amount)
                },
                openSettings: { gasLimit, rate, settings in
                    self.openTransactionSettings(gasLimit: gasLimit, rate: rate, settings: settings)
                }
            )
        )
        vc.viewModel = viewModel
        self.rootViewController = vc
        self.navigationController = UINavigationController(rootViewController: vc)
    }
    
    public func appCoordinatorShouldOpenExchangeForToken(_ token: Token, isReceived: Bool = false) {
        self.navigationController.popToRootViewController(animated: true)
        self.rootViewController.viewModel.currentChain.value = AppState.shared.currentChain
        if isReceived {
            self.rootViewController.viewModel.updateDestToken(token: token)
        } else {
            self.rootViewController.viewModel.updateSourceToken(token: token)
        }
    }
    
    public func appCoordinatorOpenSwap(from: Token, to: Token) {
        self.navigationController.popToRootViewController(animated: true)
        self.rootViewController.viewModel.currentChain.value = AppState.shared.currentChain
        self.rootViewController.viewModel.updateSourceToken(token: from)
        self.rootViewController.viewModel.updateDestToken(token: to)
    }
    
    func openSwapConfirm(object: SwapObject, quoteToken: TokenDetailInfo) {
        let viewModel = SwapSummaryViewModel(swapObject: object)
        viewModel.quoteTokenDetail = quoteToken
        let swapSummaryVC = SwapSummaryViewController.instantiateFromNib()
        swapSummaryVC.viewModel = viewModel
//        swapSummaryVC.delegate = rootViewController
        let nav = UINavigationController(rootViewController: swapSummaryVC)
        nav.modalPresentationStyle = .overFullScreen
        self.rootViewController.present(nav, animated: true)
        AppDependencies.tracker.track("swap_confirm_pop_up_open", properties: ["screenid": "swap_confirm_pop_up"])
    }
    
    func openTransactionSettings(gasLimit: BigInt, rate: Rate?, settings: SwapTransactionSettings) {
        let advancedGasLimit = (settings.advanced?.gasLimit).map(String.init)
        let advancedMaxPriorityFee = (settings.advanced?.maxPriorityFee).map {
            return NumberFormatUtils.format(value: $0, decimals: 9, maxDecimalMeaningDigits: 2, maxDecimalDigits: 2)
        }
        let advancedMaxFee = (settings.advanced?.maxFee).map {
            return NumberFormatUtils.format(value: $0, decimals: 9, maxDecimalMeaningDigits: 2, maxDecimalDigits: 2)
        }
        let advancedNonce = (settings.advanced?.nonce).map { "\($0)" }
        
        let vm = TransactionSettingsViewModel(chain: AppState.shared.currentChain, gasLimit: gasLimit, selectType: settings.basic?.gasPriceType ?? .medium, rate: rate, defaultOpenAdvancedMode: settings.advanced != nil)
        let popup = TransactionSettingsViewController(viewModel: vm)
        vm.update(priorityFee: advancedMaxPriorityFee, maxGas: advancedMaxFee, gasLimit: advancedGasLimit, nonceString: advancedNonce)
        
        vm.saveEventHandler = { [weak self] swapSettings in
            self?.rootViewController.viewModel.updateSettings(settings: swapSettings)
        }
        self.navigationController.pushViewController(popup, animated: true)
        AppDependencies.tracker.track("swap_txn_setting_pop_up_open", properties: ["screenid": "swap_txn_setting_pop_up"])
    }
    
    func openApprove(token: Token, amount: BigInt) {
        let param = ApprovePopup.ApproveParam(symbol: token.symbol, tokenAddress: token.address, remain: amount, toAddress: AppState.shared.currentChain.proxyAddress(), chain: AppState.shared.currentChain, gasLimit: AppDependencies.gasConfig.defaultApproveGasLimit)
        ApprovePopup.show(on: rootViewController, param: param) { txHash in }
    }
    
    func openTransactionHistory() {
        AppDependencies.router.openTransactionHistory()
    }
}


public extension SwapCoordinator {
    func appCoordinatorReceivedTokensSwapFromUniversalLink(srcTokenAddress: String?, destTokenAddress: String?, chainIdString: String?) {
        // default swap screen
//        self.navigationController.tabBarController?.selectedIndex = 1
//        self.navigationController.popToRootViewController(animated: false)
//        guard let chainIdString = chainIdString else {
//            return
//        }
//        
//        let chainId = Int(chainIdString) ?? AllChains.ethMainnetPRC.chainID
//        //switch chain if need
//        if KNGeneralProvider.shared.customRPC.chainID != chainId {
//            let chain = ChainType.make(chainID: chainId) ?? .eth
//            self.rootViewController.showSwitchChainAlert(chain, "Please switch to \(chain.chainName()) to swap".toBeLocalised()) {
//                self.prepareTokensForSwap(srcTokenAddress: srcTokenAddress, destTokenAddress: destTokenAddress, chainId: chainId, isFromDeepLink: true)
//            }
//        } else {
//            self.prepareTokensForSwap(srcTokenAddress: srcTokenAddress, destTokenAddress: destTokenAddress, chainId: chainId, isFromDeepLink: true)
//        }
    }
    
    func prepareTokensForSwap(srcTokenAddress: String?, destTokenAddress: String?, chainId: Int, isFromDeepLink: Bool = false) {
        // default token
//        var fromToken = KNGeneralProvider.shared.currentChain.quoteTokenObject()
//        var toToken = KNGeneralProvider.shared.currentChain.defaultToSwapToken()
//
//        var newAddress: [String] = []
//        guard let srcTokenAddress = srcTokenAddress, let destTokenAddress = destTokenAddress else {
//            self.rootViewController.viewModel.loadBaseToken()
//            return
//        }
//
//        let isValidSrcAddress = KNGeneralProvider.shared.isAddressValid(address: srcTokenAddress)
//        let isValidDestTokenAddress = KNGeneralProvider.shared.isAddressValid(address: destTokenAddress)
//
//        guard isValidSrcAddress, isValidDestTokenAddress else {
//            self.rootViewController.viewModel.loadBaseToken()
//            return
//        }
//        // in case can get token with given address
//        if let token = KNSupportedTokenStorage.shared.get(forPrimaryKey: srcTokenAddress) {
//            fromToken = token
//        } else {
//            newAddress.append(srcTokenAddress)
//        }
//
//        if let token = KNSupportedTokenStorage.shared.get(forPrimaryKey: destTokenAddress) {
//            toToken = token
//        } else {
//            newAddress.append(destTokenAddress)
//        }
//        if newAddress.isEmpty {
//            // there are no new address then show swap screen
//            self.updateToken(sourceToken: fromToken.toToken(), destToken: toToken.toToken())
//        } else if isFromDeepLink {
//            self.getTokenDetailInfo(sourceAddress: srcTokenAddress, destAddress: destTokenAddress) { sourceToken, destToken in
//                self.updateToken(sourceToken: sourceToken, destToken: destToken)
//            }
//        }
    }
    
    func updateToken(sourceToken: Token?, destToken: Token?) {
        if let sourceToken = sourceToken {
            self.rootViewController.viewModel.updateSourceToken(token: sourceToken)
        }
        if let destToken = destToken {
            self.rootViewController.viewModel.updateDestToken(token: destToken)
        }
    }
    
    func getTokenDetailInfo(sourceAddress: String?, destAddress: String?, completion: @escaping (_ sourceToken: Token?, _ destToken: Token?) -> Void) {
        var sourceToken: Token?
        var destToken: Token?
        
        let group = DispatchGroup()
        self.rootViewController.showLoadingHUD()
        if let sourceAddress = sourceAddress {
            group.enter()
            self.swapRepository.getTokenDetail(tokenAddress: sourceAddress) { token in
                group.leave()
                if let token = token {
                    sourceToken = Token(name: token.name, symbol: token.symbol, address: token.address, decimals: token.decimals, logo: token.logo)
                }
            }
        }
        
        if let destAddress = destAddress {
            group.enter()
            self.swapRepository.getTokenDetail(tokenAddress: destAddress) { token in
                group.leave()
                if let token = token {
                    destToken = Token(name: token.name, symbol: token.symbol, address: token.address, decimals: token.decimals, logo: token.logo)
                }
            }
        }
        
        group.notify(queue: .main) {
            DispatchQueue.main.async {
                self.rootViewController.hideLoading()
            }
            completion(sourceToken, destToken)
        }
    }
}

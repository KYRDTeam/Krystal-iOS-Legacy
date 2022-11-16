//
//  UnstakeViewModel.swift
//  EarnModule
//
//  Created by Com1 on 14/11/2022.
//

import UIKit
import Services
import BigInt
import Utilities
import TransactionModule
import AppState
import Dependencies
import FittedSheets

protocol UnstakeViewModelDelegate: class {
    func didGetDataSuccess()
    func didGetDataNeedApproveToken()
    func didGetDataFail(errMsg: String)
}

class UnstakeViewModel {
    let displayDepositedValue: String
    let ratio: BigInt
    let stakingTokenSymbol: String
    let toTokenSymbol: String
    let balance: BigInt
    let platform: Platform
    var unstakeValue: BigInt = BigInt(0) {
        didSet {
            self.configAllowance()
        }
    }
    let chain: ChainType
    var setting: TxSettingObject = .default
    let stakingTokenAddress: String
    let stakingTokenLogo: String
    let toTokenLogo: String
    let toUnderlyingTokenAddress: String
    var stakingTokenAllowance: BigInt = BigInt(0)
    var contractAddress: String?
    var showRevertedRate: Bool = false
    weak var delegate: UnstakeViewModelDelegate?
    
    let apiService = EarnServices()
    var buildTxRequestParams: JSONDictionary {
        var earningType: String = platform.type
        if stakingTokenSymbol.lowercased() == "MATIC".lowercased() {
            earningType = "stakingMATIC"
        }
        var params: JSONDictionary = [
            "tokenAmount": unstakeValue.description,
            "chainID": chain.getChainId(),
            "earningType": earningType,
            "platform": platform.name,
            "userAddress": AppState.shared.currentAddress.addressString,
            "tokenAddress": toUnderlyingTokenAddress
        ]
        if platform.name.lowercased() == "ankr" {
            var useC = false
            if stakingTokenSymbol.suffix(1).description.lowercased() == "c" {
                useC = true
            }
            
            params["extraData"] = ["ankr": ["useTokenC": useC]]
        }
        return params
    }
    var txObject: TxObject?
    var gasLimit: BigInt = AppDependencies.gasConfig.earnGasLimitDefault

    init(earningBalance: EarningBalance) {
        self.displayDepositedValue = (BigInt(earningBalance.stakingToken.balance)?.shortString(decimals: earningBalance.stakingToken.decimals) ?? "---") + " " + earningBalance.stakingToken.symbol
        self.ratio = BigInt(earningBalance.ratio)
        self.stakingTokenSymbol = earningBalance.stakingToken.symbol
        self.toTokenSymbol = earningBalance.toUnderlyingToken.symbol
        self.balance = BigInt(earningBalance.stakingToken.balance) ?? BigInt(0)
        self.platform = earningBalance.platform
        self.chain = ChainType.make(chainID: earningBalance.chainID) ?? AppState.shared.currentChain
        self.toUnderlyingTokenAddress = earningBalance.toUnderlyingToken.address
        self.stakingTokenAddress = earningBalance.stakingToken.address
        self.stakingTokenLogo = earningBalance.stakingToken.logo
        self.toTokenLogo = earningBalance.toUnderlyingToken.logo
    }
    
    func unstakeValueString() -> String {
        NumberFormatUtils.balanceFormat(value: unstakeValue, decimals: 18)
    }
    
    func receivedValue() -> BigInt {
        return unstakeValue * self.ratio / BigInt(10).power(18)
    }
    
    func receivedValueString() -> String {
        return NumberFormatUtils.balanceFormat(value: receivedValue(), decimals: 18)
    }
    
    func receivedInfoString() -> String {
        return receivedValueString() + " " + toTokenSymbol
    }
    
    func receivedValueMaxString() -> String {
        let maxValue = balance * self.ratio / BigInt(10).power(18)
        return NumberFormatUtils.balanceFormat(value: maxValue, decimals: 18)
    }
    
    func showRateInfo() -> String {
        if showRevertedRate {
            let ratioString = NumberFormatUtils.balanceFormat(value: BigInt(10).power(36) / ratio, decimals: 18)
            return "1 \(toTokenSymbol) = \(ratioString) \(stakingTokenSymbol)"
        } else {
            let ratioString = NumberFormatUtils.balanceFormat(value: ratio, decimals: 18)
            return "1 \(stakingTokenSymbol) = \(ratioString) \(toTokenSymbol)"
        }
    }
    
    func approve(controller: UIViewController, onSuccess: @escaping (() -> Void), onFail: @escaping (() -> Void)) {
        let vm = ApproveTokenViewModel(symbol: stakingTokenSymbol, tokenAddress: stakingTokenAddress, remain: stakingTokenAllowance, toAddress: contractAddress ?? "", chain: chain)
        let vc = ApproveTokenViewController(viewModel: vm)
        vc.onSuccessApprove = {
            onSuccess()
        }
        
        vc.onFailApprove = {
            onFail()
        }
        
        controller.present(vc, animated: true, completion: nil)
    }
    
    func openUnStakeSummary(controller: UIViewController) {
        requestBuildUnstakeTx(completion: {
            if let tx = self.txObject {
                
                let displayInfo = UnstakeDisplayInfo(amount: self.unstakeValueString(),
                                                     receiveAmount: self.receivedValueString(),
                                                     rate: self.showRateInfo(),
                                                     fee: self.transactionFeeString(),
                                                     stakeTokenIcon: self.stakingTokenLogo,
                                                     toTokenIcon:self.toTokenLogo,
                                                     fromSym: self.stakingTokenSymbol,
                                                     toSym: self.toTokenSymbol)
                
                
                let viewModel = UnstakeSummaryViewModel(setting: self.setting, txObject: tx, platform: self.platform, displayInfo: displayInfo)
                
                TxConfirmPopup.show(onViewController: controller, withViewModel: viewModel) { pendingTx in
                    if let pendingTx = pendingTx as? PendingUnstakeTxInfo {
                        self.openTxStatusPopup(tx: pendingTx, controller: controller)
                    }
                }
            }
        })
    }
    
    func openTxStatusPopup(tx: PendingUnstakeTxInfo, controller: UIViewController) {
        let popup = StakingTrasactionProcessPopup.instantiateFromNib()
        popup.tx = tx
        let sheet = SheetViewController(controller: popup, sizes: [.fixed(420)], options: .init(pullBarHeight: 0))
        controller.navigationController?.popViewController(animated: true)
        UIApplication.shared.topMostViewController()?.present(sheet, animated: true)
    }
    
    func timeForUnstakeString() -> String {
        let isAnkr = platform.name.lowercased() == "ANKR".lowercased()
        let isLido = platform.name.lowercased() == "LIDO".lowercased()
        
        var time = ""
        if toTokenSymbol.lowercased() == "AVAX".lowercased() && isAnkr {
            time = "4 weeks"
        } else if toTokenSymbol.lowercased() == "BNB".lowercased() && isAnkr {
            time = "7-14 days"
        } else if toTokenSymbol.lowercased() == "FTM".lowercased() && isAnkr {
            time = "35 days"
        } else if toTokenSymbol.lowercased() == "MATIC".lowercased() && isAnkr {
            time = "3-4 days"
        } else if toTokenSymbol.lowercased() == "SOL".lowercased() && isLido {
            time = "2-3 days"
        }
        
        return "You will receive your \(toTokenSymbol) in \(time)"
    }
    
    func transactionFeeString() -> String {
        return NumberFormatUtils.gasFee(value: setting.transactionFee(chain: chain)) + " " + AppState.shared.currentChain.quoteToken()
    }
    
    func fetchData(controller: UIViewController) {
        controller.showLoadingHUD()
        apiService.getStakingOptionDetail(platform: platform.name, earningType: platform.type, chainID: "\(chain.getChainId())", tokenAddress: toUnderlyingTokenAddress) { result in
            switch result {
            case .success(let detail):
                if let earningToken = detail.earningTokens.first(where: { $0.address.lowercased() == self.stakingTokenAddress.lowercased() }) {
                    self.contractAddress = detail.poolAddress
                    self.checkNeedApprove(earningToken: earningToken, controller: controller)
                } else {
                    controller.hideLoading()
                    self.delegate?.didGetDataSuccess()
                }
            case .failure(let error):
                controller.hideLoading()
                self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
            }
        }
    }
    
    func checkNeedApprove(earningToken: EarningToken, controller: UIViewController) {
        guard let contractAddress = contractAddress else { return }
        let service = EthereumNodeService(chain: chain)
        if earningToken.requireApprove {
            service.getAllowance(for: AppState.shared.currentAddress.addressString, networkAddress: contractAddress, tokenAddress: earningToken.address) { result in
                controller.hideLoading()
                switch result {
                case .success(let number):
                    self.stakingTokenAllowance = number
                    self.configAllowance()
                case .failure(let error):
                    self.delegate?.didGetDataFail(errMsg: error.localizedDescription)
                }
            }
        } else {
            controller.hideLoading()
            self.stakingTokenAllowance = TransactionConstants.maxTokenAmount
            self.delegate?.didGetDataSuccess()
        }
    }
    
    func requestBuildUnstakeTx(showLoading: Bool = false, completion: @escaping () -> () = {}) {
        
        apiService.buildUnstakeTx(param: buildTxRequestParams) { result in
            switch result {
            case .success(let tx):
                self.txObject = tx
                self.gasLimit = BigInt(tx.gasLimit.drop0x, radix: 16) ?? AppDependencies.gasConfig.earnGasLimitDefault
                completion()
            case .failure(let error):
                //TODO : Show error here
                print(error.localizedDescription)
            }
            
        }
    }
    
    func configAllowance() {
        if stakingTokenAllowance < unstakeValue {
            //need approve more
            self.delegate?.didGetDataNeedApproveToken()
        } else {
            // can make transaction
            self.delegate?.didGetDataSuccess()
        }
    }
}

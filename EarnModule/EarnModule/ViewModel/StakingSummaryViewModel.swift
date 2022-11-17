//
//  StakingSummaryViewModel.swift
//  EarnModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import KrystalWallets
import BigInt
import AppState
import Result
import APIKit
import JSONRPCKit
import Services
import Dependencies
import TransactionModule

class StakingSummaryViewModel: TxConfirmViewModelProtocol {
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }
    
    var currentNonce: Int {
        return AppDependencies.nonceStorage.currentNonce(chain: currentChain, address: currentAddress.addressString)
    }
    
    let earnToken: EarningToken
    let txObject: TxObject
    var setting: TxSettingObject
    let token: Token
    let platform: EarnPlatform
    let displayInfo: StakeDisplayInfo
    
    var shouldDiplayLoading: Observable<Bool> = .init(false)
    var txManager: TxProcessorProtocol!
    var service: EthereumNodeService!
    var converter: TxObjectConverter!

    init(earnToken: EarningToken, txObject: TxObject, setting: TxSettingObject, token: Token, platform: EarnPlatform, displayInfo: StakeDisplayInfo) {
        self.earnToken = earnToken
        self.token = token
        self.platform = platform
        self.displayInfo = displayInfo
        self.txObject = txObject
        self.setting = setting
        self.service = EthereumNodeService(chain: currentChain)
        self.converter = TxObjectConverter(chain: currentChain)
    }
    
    var title: String {
        return Strings.stakeSummary
    }
    
    var chain: ChainType {
        return currentChain
    }
    
    var action: String {
        return Strings.youAreStaking
    }
    
    var tokenIconURL: String {
        return token.logo
    }
    
    var tokenAmountString: String {
        return displayInfo.amount
    }
    
    var platformName: String {
        return platform.name.uppercased()
    }
    
    var buttonTitle: String {
        return Strings.confirmStake
    }
    
    var rows: [TxInfoRowData] {
        return [
            .init(title: Strings.apyTitle, value: displayInfo.apy, isHighlighted: true),
            .init(title: Strings.youWillReceive, value: displayInfo.receiveAmount),
            .init(title: Strings.rate, value: displayInfo.rate),
            .init(title: Strings.networkFee, value: displayInfo.fee),
        ]
    }
    
    var isRequesting: Bool = false
    
    var onError: (String) -> Void = { _ in }
    
    var onSuccess: (PendingTxInfo) -> Void = { _ in }
    
    var onSelectOpenSetting: (() -> ())? = nil
    
    func onTapConfirm() {
        sendTransaction()
    }
    
    func onSettingChanged(settingObject: TxSettingObject) {
        setting = settingObject
    }
    
    func sendTransaction() {
        getLatestNonce { [weak self] _ in
            if AppState.shared.currentChain.isSupportedEIP1559() {
                self?.request1559Staking()
            } else {
                self?.requestLegacyStaking()
            }
        }
    }
}


// MARK: - Process transaction
extension StakingSummaryViewModel {
    
    func request1559Staking() {
        guard let eip1559Tx = converter.convertToEIP1559Transaction(txObject: txObject, address: currentAddress.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: eip1559Tx.fromAddress,
            to: eip1559Tx.toAddress,
            value: BigInt(eip1559Tx.value.drop0x, radix: 16) ?? BigInt(0),
            data: Data(hexString: eip1559Tx.data) ?? Data(),
            gasPrice: BigInt(eip1559Tx.maxGasFee.drop0x, radix: 16) ?? BigInt(0)
        )
        service.getEstimateGasLimit(request: request, chain: currentChain) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if let signedData = EIP1559TransactionSigner().signTransaction(address: self.currentAddress, eip1559Tx: eip1559Tx) {
                    TransactionManager.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            let pendingTx = PendingStakingTxInfo(
                                token: self.token,
                                platform: self.platform,
                                selectedDestToken: self.earnToken,
                                sourceAmount: self.displayInfo.amount,
                                destAmount: self.displayInfo.receiveAmount,
                                legacyTx: nil,
                                eip1559Tx: eip1559Tx,
                                chain: self.currentChain,
                                date: Date(),
                                hash: hash,
                                nonce: Int(eip1559Tx.nonce) ?? self.currentNonce
                            )
                            TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                            self.onSuccess(pendingTx)
                        case .failure(let error):
                            self.onError(TxErrorParser.parse(error: error).message)
                        }
                    }
                } else {
                    self.onError("Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.onError(txError.message)
            }
        }
    }
    
    func requestLegacyStaking() {
        guard let legacyTx = converter.convertToLegacyTransaction(txObject: txObject, address: currentAddress.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: legacyTx.address,
            to: legacyTx.to,
            value: legacyTx.value,
            data: legacyTx.data,
            gasPrice: legacyTx.gasPrice
        )
        service.getEstimateGasLimit(request: request, chain: currentChain) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                let signResult = EthereumTransactionSigner().signTransaction(address: self.currentAddress, transaction: legacyTx)
                switch signResult {
                case .success(let signedData):
                    TransactionManager.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            let pendingTx = PendingStakingTxInfo(
                                token: self.token,
                                platform: self.platform,
                                selectedDestToken: self.earnToken,
                                sourceAmount: self.displayInfo.amount,
                                destAmount: self.displayInfo.receiveAmount,
                                legacyTx: legacyTx,
                                eip1559Tx: nil,
                                chain: self.currentChain,
                                date: Date(),
                                hash: hash,
                                nonce: legacyTx.nonce
                            )
                            TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                            self.onSuccess(pendingTx)
                        case .failure(let error):
                            self.onError(TxErrorParser.parse(error: error).message)
                        }
                    }
                case .failure:
                    self.onError("Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.onError(txError.message)
            }
        }
    }
    
    func getLatestNonce(completion: @escaping (Int?) -> ()) {
        service.getTransactionCount(address: currentAddress.addressString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let nonce):
                AppDependencies.nonceStorage.updateNonce(chain: self.currentChain, address: self.currentAddress.addressString, value: nonce)
                completion(nonce)
            default:
                completion(nil)
            }
        }
    }
    
    
}

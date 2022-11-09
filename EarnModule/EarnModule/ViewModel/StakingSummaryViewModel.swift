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

class StakingSummaryViewModel {
    
    var currentAddress: KAddress {
        return AppState.shared.currentAddress
    }
    
    var currentChain: ChainType {
        return AppState.shared.currentChain
    }
    
    //  var gasPrice: BigInt
    var gasLimit: BigInt
    
    let txObject: TxObject
    let setting: TxSettingObject
    let displayInfo: StakeDisplayInfo
    var shouldDiplayLoading: Observable<Bool> = .init(false)
    var errorMessage: Observable<String> = .init("")
    var processor: TxProcessorProtocol!
    var service: EthereumNodeService!
    var converter: TxObjectConverter!
    var onSendTxSuccess: (() -> ())?
    
    init(txObject: TxObject, setting: TxSettingObject, displayInfo: StakeDisplayInfo) {
        self.txObject = txObject
        self.setting = setting
        self.displayInfo = displayInfo
        self.gasLimit = BigInt(txObject.gasLimit.drop0x, radix: 16) ?? Constants.earnGasLimitDefault
        self.service = EthereumNodeService(chain: currentChain)
        self.converter = TxObjectConverter(chain: currentChain)
    }
    
    func sendTransaction() {
        if AppState.shared.currentChain.isSupportedEIP1559() {
            request1559Staking()
        } else {
            requestLegacyStaking()
        }
    }
    
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
                    AppDependencies.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            self.onSendTxSuccess?()
                        case .failure(let error):
                            self.showError(errorMsg: TxErrorParser.parse(error: error).message)
                        }
                    }
                } else {
                    self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.showError(errorMsg: txError.message)
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
                    AppDependencies.txProcessor.sendTxToNode(data: signedData, chain: self.currentChain) { result in
                        switch result {
                        case .success(let hash):
                            self.onSendTxSuccess?()
                        case .failure(let error):
                            self.showError(errorMsg: TxErrorParser.parse(error: error).message)
                        }
                    }
                case .failure:
                    self.showError(errorMsg: "Something went wrong, please try again later".toBeLocalised())
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                self.showError(errorMsg: txError.message)
            }
        }
    }
    
    func getLatestNonce(completion: @escaping (Int?) -> Void) {
        let address = AppState.shared.currentAddress.addressString
        let web3Client = EthereumNodeService(chain: AppState.shared.currentChain)
        web3Client.getTransactionCount(address: address) { result in
            switch result {
            case .success(let nonce):
                AppDependencies.nonceStorage.updateNonce(chain: AppState.shared.currentChain, address: address, value: nonce)
                completion(nonce)
            default:
                completion(nil)
            }
        }
    }
    
    func showError(errorMsg: String) {
        errorMessage.value = errorMsg
    }
    
}

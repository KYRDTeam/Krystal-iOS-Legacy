//
//  ApproveTokenViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 19/12/2022.
//

import BigInt
import AppState
import Dependencies
import BaseModule
import BaseWallet
import Utilities
import Services
import Result

public class ApproveTokenViewModel {
    var showEditSettingButton: Bool = false
    var gasLimit: BigInt = AppDependencies.gasConfig.defaultApproveGasLimit
    var value: BigInt = TransactionConstants.maxTokenAmount
    var headerTitle: String = "Approve Token"
    var chain: ChainType
    var tokenAddress: String
    var hash: String?
    let remain: BigInt
    var gasPrice: BigInt = AppDependencies.gasConfig.getStandardGasPrice(chain: AppState.shared.currentChain)
    var toAddress: String
    
    var subTitleText: String {
        return String(format: "You need to approve Krystal to spend %@", self.symbol.uppercased())
    }
    var state: Bool {
        return false
    }
    var symbol: String
    var setting: TxSettingObject = .default
    
    
    func getFee() -> BigInt {
        let fee = self.gasPrice * self.gasLimit
        return fee
    }
    
    func getFeeString() -> String {
        let fee = self.getFee()
        return "\(NumberFormatUtils.gasFeeFormat(number: fee)) \(chain.quoteToken())"
    }
    
    func getFeeUSDString() -> String {
        let quoteUSD = AppDependencies.priceStorage.getQuoteUsdRate(chain: chain) ?? 0
        let feeUSD = self.getFee() * BigInt(quoteUSD * pow(10.0, 18.0)) / BigInt(10).power(18)
        let valueString: String =  feeUSD.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)
        return "(~ \(valueString) USD)"
    }
    
    public init(symbol: String, tokenAddress: String, remain: BigInt, toAddress: String, chain: ChainType) {
        self.symbol = symbol
        self.tokenAddress = tokenAddress
        self.remain = remain
        self.toAddress = toAddress
        self.chain = chain
    }
    
    func getGasPrice(chain: ChainType, setting: TxSettingObject) -> BigInt {
        if let basic = setting.basic {
            switch basic.gasType {
            case .slow:
                return AppDependencies.gasConfig.getLowGasPrice(chain: chain)
            case .regular:
                return AppDependencies.gasConfig.getStandardGasPrice(chain: chain)
            case .fast:
                return AppDependencies.gasConfig.getFastGasPrice(chain: chain)
            case .superFast:
                return AppDependencies.gasConfig.getSuperFastGasPrice(chain: chain)
            }
        } else {
            return setting.advanced?.maxFee ?? .zero
        }
    }
    
    func sendApproveRequest(value: BigInt, onCompleted: @escaping (Error?) -> Void) {
        let service = EthereumNodeService(chain: chain)
        let gasPrice = self.getGasPrice(chain: chain, setting: setting)
        service.getSendApproveERC20TokenEncodeData(spender: toAddress, value: value) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let hex):
                self.getLatestNonce { nonce in
                    guard let nonce = nonce else {
                        return
                    }
                    let gasLimit = self.setting.advanced?.gasLimit ?? self.gasLimit
                    let legacyTx = LegacyTransaction(
                        value: BigInt(0),
                        address: AppState.shared.currentAddress.addressString,
                        to: self.tokenAddress,
                        nonce: nonce,
                        data: hex,
                        gasPrice: gasPrice,
                        gasLimit: gasLimit,
                        chainID: self.chain.getChainId()
                    )
                    let signResult = EthereumTransactionSigner().signTransaction(address: AppState.shared.currentAddress, transaction: legacyTx)
                    switch signResult {
                    case .success(let signedData):
                        TransactionManager.txProcessor.sendTx(data: signedData, chain: self.chain) { result in
                            switch result {
                            case .success(let hash):
                                self.hash = hash
                                let pendingTx = ApprovePendingTxInfo(
                                    legacyTx: legacyTx,
                                    eip1559Tx: nil,
                                    chain: self.chain,
                                    date: Date(),
                                    hash: hash,
                                    nonce: legacyTx.nonce,
                                    walletAddress: AppState.shared.currentAddress.addressString,
                                    contractAddress: self.toAddress
                                )
                                TransactionManager.txProcessor.savePendingTx(txInfo: pendingTx)
                                onCompleted(nil)
                            case .failure(let error):
                                onCompleted(error)
                            }
                        }
                    case .failure(let error):
                        onCompleted(error)
                    }
                    
                }
            case .failure(let error):
                onCompleted(error)
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
}

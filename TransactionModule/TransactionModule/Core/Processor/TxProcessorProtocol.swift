//
//  TxManagerProtocol.swift
//  Dependencies
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import BaseWallet
import Result
import Services
import KrystalWallets
import Dependencies
import BigInt

public struct TxProcessResult {
    public var hash: String
    public var legacyTx: LegacyTransaction?
    public var eip1559Tx: EIP1559Transaction?
}

public protocol TxProcessorProtocol {
    var txSender: TxNodeSenderProtocol { get set }
    func hasPendingTx() -> Bool
    func observePendingTxListChanged()
    func process(address: KAddress, chain: ChainType, txObject: TxObject, setting: TxSettingObject,
                 completion: @escaping (Result<TxProcessResult, TxError>) -> Void)
    func sendTx(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void)
    func savePendingTx(txInfo: PendingTxInfo)
}

public extension TxProcessorProtocol {
    
    func sendTx(data: Data, chain: ChainType, completion: @escaping (Result<String, AnyError>) -> Void) {
        txSender.sendTx(data: data, chain: chain, completion: completion)
    }
    
    func process(address: KAddress, chain: ChainType, txObject: TxObject, setting: TxSettingObject, completion: @escaping (Result<TxProcessResult, TxError>) -> Void) {
        getLatestNonce(address: address, chain: chain) { _ in
            if chain.isSupportedEIP1559() {
                self.requestEIP1559Tx(address: address, chain: chain, txObject: txObject, setting: setting, completion: completion)
            } else {
                self.requestLegacyTx(address: address, chain: chain, txObject: txObject, setting: setting, completion: completion)
            }
        }
    }
    
    func requestEIP1559Tx(address: KAddress, chain: ChainType, txObject: TxObject, setting: TxSettingObject, completion: @escaping (Result<TxProcessResult, TxError>) -> Void) {
        guard let eip1559Tx = TxObjectConverter(chain: chain).convertToEIP1559Transaction(txObject: txObject, address: address.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: eip1559Tx.fromAddress,
            to: eip1559Tx.toAddress,
            value: BigInt(eip1559Tx.value.drop0x, radix: 16) ?? BigInt(0),
            data: Data(hexString: eip1559Tx.data) ?? Data(),
            gasPrice: BigInt(eip1559Tx.maxGasFee.drop0x, radix: 16) ?? BigInt(0)
        )
        EthereumNodeService(chain: chain).getEstimateGasLimit(request: request, chain: chain) { result in
            switch result {
            case .success:
                if let signedData = EIP1559TransactionSigner().signTransaction(address: address, eip1559Tx: eip1559Tx) {
                    self.txSender.sendTx(data: signedData, chain: chain) { result in
                        switch result {
                        case .success(let hash):
                            completion(.success(.init(hash: hash, legacyTx: nil, eip1559Tx: eip1559Tx)))
                        case .failure(let error):
                            let txError = TxErrorParser.parse(error: error)
                            completion(.failure(txError))
                        }
                    }
                } else {
                    completion(.failure(TxError.undefined))
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                completion(.failure(txError))
            }
        }
    }
    
    func requestLegacyTx(address: KAddress, chain: ChainType, txObject: TxObject, setting: TxSettingObject, completion: @escaping (Result<TxProcessResult, TxError>) -> Void) {
        guard let legacyTx = TxObjectConverter(chain: chain).convertToLegacyTransaction(txObject: txObject, address: address.addressString, setting: setting) else {
            return
        }
        let request = KNEstimateGasLimitRequest(
            from: legacyTx.address,
            to: legacyTx.to,
            value: legacyTx.value,
            data: legacyTx.data,
            gasPrice: legacyTx.gasPrice
        )
        EthereumNodeService(chain: chain).getEstimateGasLimit(request: request, chain: chain) { result in
            switch result {
            case .success:
                let signResult = EthereumTransactionSigner().signTransaction(address: address, transaction: legacyTx)
                switch signResult {
                case .success(let signedData):
                    self.txSender.sendTx(data: signedData, chain: chain) { result in
                        switch result {
                        case .success(let hash):
                            completion(.success(.init(hash: hash, legacyTx: legacyTx, eip1559Tx: nil)))
                        case .failure(let error):
                            let txError = TxErrorParser.parse(error: error)
                            completion(.failure(txError))
                        }
                    }
                case .failure(let error):
                    let txError = TxErrorParser.parse(error: error)
                    completion(.failure(txError))
                }
            case .failure(let error):
                let txError = TxErrorParser.parse(error: error)
                completion(.failure(txError))
            }
        }
    }
    
    
    func getLatestNonce(address: KAddress, chain: ChainType, completion: @escaping (Int?) -> ()) {
        let service = EthereumNodeService(chain: chain)
        service.getTransactionCount(address: address.addressString) { result in
            switch result {
            case .success(let nonce):
                AppDependencies.nonceStorage.updateNonce(chain: chain, address: address.addressString, value: nonce)
                completion(nonce)
            default:
                completion(nil)
            }
        }
    }
}

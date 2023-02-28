//
//  UserService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 21/09/2022.
//

import Foundation
import Moya
import KrystalWallets
import AppState
import TransactionModule
import Utilities
import WalletCore

class UserService {
    
    enum TransactionType: String {
        case swap
        case transfer
        case multisend
        case bridge
        case stake
        case unstake
        case claim
        case nft_transfer
        case undefine
    }
    
    enum TransactionState: String {
        case pending
        case success
        case failed
    }
    
    enum ChainType: String {
        case evm
        case solana
    }
    
    static let retryTimes = 3
    
    let provider = MoyaProvider<UserEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    
    static let shared = UserService()
    
    func connect(remainRetryTime: Int = UserService.retryTimes, address: KAddress, completion: @escaping () -> ()) {
        let signer = SignerFactory().getSigner(address: address)
        let message = "\(address.addressString)_\(Int(Date().timeIntervalSince1970))"
        guard let signature = try? signer.signMessageHash(address: address, data: Data(message.utf8), addPrefix: true) else {
            completion()
            return
        }
        let request: UserEndpoint = {
            switch address.addressType {
            case .evm:
                return UserEndpoint.connectEvm(address: address.addressString, signature: signature.hexEncoded)
            case .solana:
                return UserEndpoint.connectSolana(address: address.addressString, signature: Base58.encodeNoCheck(data: signature))
            }
        }()
        provider.requestWithFilter(request) { result in
            switch result {
            case .success(let response):
                do {
                    let resp = try JSONDecoder().decode(ConnectEVMResponse.self, from: response.data)
                    UserDefaults.standard.saveAuthToken(address: address.addressString, token: resp.token)
                    completion()
                } catch {
                    return
                }
            case .failure:
                if remainRetryTime > 0 {
                    self.connect(remainRetryTime: remainRetryTime - 1, address: address, completion: completion)
                } else {
                    completion()
                }
            }
        }
    }
    
    func submitTransaction(transaction: [String: Any], completion: ((Bool) -> Void)? = nil) {
        provider.requestWithFilter(.submitTransaction(transaction: transaction)) { result in
            switch result {
            case .success:
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }
    
    func submitTransaction(tx: InternalHistoryTransaction, completion:((Bool) -> Void)? = nil) {
        let type = tx.type.getTransactionType()
        let chainType = tx.getChainType()
        let state = tx.getTxState()
        
        let param = UserService.buildTransactionParam(type: type, chainType: chainType, txHash: tx.hash, status: state, extra: tx.trackingExtraData)
        submitTransaction(transaction: param, completion: completion)
    }
    
    class func buildTransactionParam(type: TransactionType, chainType: ChainType, txHash: String, status: TransactionState, extra: TxTrackingExtraData? = nil) -> [String: Any] {
        let address = AppState.shared.currentAddress.addressString
        let chain = AppState.shared.currentChain.getChainId()
        
        return [
            "txType": type.rawValue,
            "walletAddress": address,
            "chainType": chainType.rawValue,
            "chainId": chain,
            "txHash": txHash,
            "status": status.rawValue,
            "extra": extra.asDictionary()
        ]
    }
}

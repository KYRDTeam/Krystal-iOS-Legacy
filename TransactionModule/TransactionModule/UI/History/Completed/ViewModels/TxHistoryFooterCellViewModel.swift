//
//  TxHistoryFooterCellViewModel.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation
import Services
import BigInt
import Utilities
import BaseWallet

struct TxHistoryFooterCellViewModel {
    var chainId: Int
    var gasAmount: String
    var gasUsdValue: String
    var txHash: String
    var shortenedTxHash: String
    var isGasPositive: Bool
    
    init(tx: TxRecord) {
        self.chainId = tx.chain.chainId
        let gasFee = BigInt(tx.gas) * (BigInt(tx.gasPrice) ?? .zero)
        let symbol = ChainType.make(chainID: tx.chain.chainId)?.customRPC().quoteToken ?? ""
        
        isGasPositive = gasFee > 0
        gasAmount = NumberFormatUtils.amount(value: gasFee, decimals: 18) + " " + symbol
        gasUsdValue = "$" + NumberFormatUtils.usdAmount(value: gasFee * BigInt(tx.historicalNativeTokenPrice * pow(10, 18)) / BigInt(10).power(18), decimals: 18)
        txHash = tx.txHash
        shortenedTxHash = tx.txHash.shortTypeAddress
    }
    
}

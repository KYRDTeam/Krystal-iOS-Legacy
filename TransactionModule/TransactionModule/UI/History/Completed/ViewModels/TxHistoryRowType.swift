//
//  TxHistoryRowType.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation

enum TxHistoryRowType {
    case date(date: Date)
    case header(viewModel: TxHistoryHeaderCellViewModel)
    case tokenChange(viewModel: TxHistoryTokenCellViewModel)
    case nft(viewModel: TxNFTCellViewModel)
    case footer(viewModel: TxHistoryFooterCellViewModel)
}

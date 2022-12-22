//
//  TxHistoryRowType.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 22/12/2022.
//

import Foundation

enum TxHistoryRowType {
    case header(viewModel: TxHistoryHeaderCellViewModel)
    case tokenChange(viewModel: TxHistoryTokenCellViewModel)
    case nft
    case footer(viewModel: TxHistoryFooterCellViewModel)
}

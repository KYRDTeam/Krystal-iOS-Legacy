//
//  FetchTransactionsUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

protocol FetchTransactionsUseCase {
  func execute(completion: @escaping ([TransactionHistoryItem]) -> ())
}

protocol FetchNextTransactionsPageUseCase {
  func loadNextPage(prevHash: String, completion: @escaping ([TransactionHistoryItem], Bool) -> ())
}


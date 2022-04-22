//
//  FetchTokensUseCase.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 22/04/2022.
//

import Foundation

protocol FetchTokensUseCase {
  func execute() -> [String]
}

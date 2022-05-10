//
//  CreateChainWalletMenuPresenter.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import Foundation

protocol CreateChainWalletMenuPresenterProtocol: AnyObject {
  var title: String { get }
  var subtitle: String { get }
}

class CreateChainWalletMenuPresenter: CreateChainWalletMenuPresenterProtocol {
  private weak var view: CreateChainWalletMenuViewProtocol?
  var chainType: ChainType
  
  var title: String {
    return String(format: Strings.chooseChainWallet, chainType.chainName())
  }
  
  var subtitle: String {
    return String(format: Strings.notHaveChainWalletPleaseCreateOrImport, chainType.chainName())
  }
  
  init(view: CreateChainWalletMenuViewProtocol?, chainType: ChainType) {
    self.view = view
    self.chainType = chainType
  }
  
}

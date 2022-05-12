//
//  CreateChainWalletMenuViewModel.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 09/05/2022.
//

import Foundation

struct CreateChainWalletMenuViewModelActions {
  var onSelectCreateNewWallet: () -> ()
  var onSelectImportWallet: () -> ()
  var onClose: () -> ()
}

class CreateChainWalletMenuViewModel {
  let chainType: ChainType
  var actions: CreateChainWalletMenuViewModelActions?
  
  init(chainType: ChainType, actions: CreateChainWalletMenuViewModelActions?) {
    self.chainType = chainType
    self.actions = actions
  }
  
  var title: String {
    return String(format: Strings.chooseChainWallet, chainType.chainName())
  }
  
  var subtitle: String {
    return String(format: Strings.notHaveChainWalletPleaseCreateOrImport, chainType.chainName())
  }
  
  func didTapCreateNewWallet() {
    actions?.onSelectCreateNewWallet()
  }
  
  func didTapImportWallet() {
    actions?.onSelectImportWallet()
  }
  
  func didTapClose() {
    actions?.onClose()
  }
}

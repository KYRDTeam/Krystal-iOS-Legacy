//
//  MultiSendCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import Foundation
import BigInt
import Result
import TrustCore
import WalletCore

class MultiSendCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  var session: KNSession
  
  weak var delegate: KNSendTokenViewCoordinatorDelegate?
  
  lazy var rootViewController: MultiSendViewController = {
    let controller = MultiSendViewController()
    controller.delegate = self
    return controller
  }()
  
  lazy var addContactVC: KNNewContactViewController = {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: "")
    let controller = KNNewContactViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    return controller
  }()
  
  fileprivate(set) var searchTokensVC: KNSearchTokenViewController?
  fileprivate(set) var approveVC: MultiSendApproveViewController?
  fileprivate(set) weak var gasPriceSelector: GasFeeSelectorPopupViewController?
  fileprivate(set) var confirmVC: MultiSendConfirmViewController?
  
  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
  }

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    
  }
}

extension MultiSendCoordinator: MultiSendViewControllerDelegate {
  func multiSendViewController(_ controller: MultiSendViewController, run event: MultiSendViewControllerEvent) {
    switch event {
    case .searchToken(let selectedToken):
      self.openSearchToken(selectedToken: selectedToken.toObject())
    case .openContactsList:
      self.openListContactsView()
    case .addContact(address: let address):
      self.openNewContact(address: address, ens: nil)
    case .checkApproval(items: let items):
      self.checkAllowance(items: items) { remaining in
        if remaining.isEmpty {
          self.rootViewController.coordinatorDidFinishApproveTokens()
        } else {
          self.openApproveView(items: remaining)
        }
      }
      
    case .confirm(items: let items):
      self.openConfirmView(items: items)
    }
  }
  
  fileprivate func openSearchToken(selectedToken: TokenObject) {
    let tokens = KNSupportedTokenStorage.shared.getAllTokenObject()
    let viewModel = KNSearchTokenViewModel(
      supportedTokens: tokens
    )
    let controller = KNSearchTokenViewController(viewModel: viewModel)
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.searchTokensVC = controller
  }
  
  fileprivate func checkAllowance(items: [MultiSendItem], completion: @escaping ([MultiSendItem]) -> Void) {
    guard let provider = self.session.externalProvider else {
      self.navigationController.showErrorTopBannerMessage(message: "You are using watch wallet")
      return
    }
    
    var remaining: [MultiSendItem] = []
    let group = DispatchGroup()
    
    items.forEach { item in
      if let address = Address(string: item.2.address) {
        group.enter()
        
        provider.getAllowance(tokenAddress: address, toAddress: Address(string: Constants.multisendBscAddress)) { result in
          switch result {
          case .success(let res):
            if item.1 > res {
              remaining.append(item)
            }
          case .failure:
            break
          }
          
          group.leave()
        }
      }
    }
    
    group.notify(queue: .main) {
      completion(remaining)
    }
  }
  
  fileprivate func openListContactsView() {
    let controller = KNListContactViewController()
    controller.loadViewIfNeeded()
    controller.delegate = self
    self.navigationController.pushViewController(controller, animated: true)
  }
  
  fileprivate func openNewContact(address: String, ens: String?) {
    let viewModel: KNNewContactViewModel = KNNewContactViewModel(address: address, ens: ens)
    self.addContactVC.updateView(viewModel: viewModel)
    self.navigationController.pushViewController(self.addContactVC, animated: true)
  }
  
  fileprivate func openApproveView(items: [MultiSendItem]) {
    let viewModel = MultiSendApproveViewModel(items: items)
    let controller = MultiSendApproveViewController(viewModel: viewModel)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.approveVC = controller
  }

  fileprivate func openConfirmView(items: [MultiSendItem]) {
    let vm = MultiSendConfirmViewModel(sendItems: items, gasPrice: BigInt(1000), gasLimit: BigInt(1000), baseGasLimit: BigInt(1000))
    let controller = MultiSendConfirmViewController(viewModel: vm)
    controller.delegate = self
    self.navigationController.present(controller, animated: true, completion: nil)
    self.confirmVC = controller
  }
  
  fileprivate func openGasPriceSelectView(_ gasLimit: BigInt, _ selectType: KNSelectedGasPriceType, _ baseGasLimit: BigInt, _ advancedGasLimit: String?, _ advancedPriorityFee: String?, _ advancedMaxFee: String?, _ advancedNonce: String?, _ controller: UIViewController) {
    let viewModel = GasFeeSelectorPopupViewModel(isSwapOption: false, gasLimit: gasLimit, selectType: selectType, isContainSlippageSection: false)
    viewModel.baseGasLimit = baseGasLimit
    viewModel.updateGasPrices(
      fast: KNGasCoordinator.shared.fastKNGas,
      medium: KNGasCoordinator.shared.standardKNGas,
      slow: KNGasCoordinator.shared.lowKNGas,
      superFast: KNGasCoordinator.shared.superFastKNGas
    )
    viewModel.advancedGasLimit = advancedGasLimit
    viewModel.advancedMaxPriorityFee = advancedPriorityFee
    viewModel.advancedMaxFee = advancedMaxFee
    viewModel.advancedNonce = advancedNonce
    let vc = GasFeeSelectorPopupViewController(viewModel: viewModel)
    vc.delegate = self
    
    self.getLatestNonce { result in
      switch result {
      case .success(let nonce):
        vc.coordinatorDidUpdateCurrentNonce(nonce)
      case .failure(let error):
        self.navigationController.showErrorTopBannerMessage(message: error.description)
      }
    }
    
    controller.present(vc, animated: true, completion: nil)
    self.gasPriceSelector = vc
  }
  
  fileprivate func openAddressListView(items: [MultiSendItem], controller: UIViewController) {
    let vm = MultisendAddressListViewModel(items: items)
    let vc = MultisendAddressListViewController(viewModel: vm)
    controller.present(vc, animated: true, completion: nil)
  }
}

extension MultiSendCoordinator: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    controller.dismiss(animated: true) {
      self.searchTokensVC = nil
      if case .select(let token) = event {
        self.rootViewController.coordinatorDidUpdateSendToken(token.toToken())
      } else if case .add(let token) = event {
        self.delegate?.sendTokenCoordinatorDidSelectAddToken(token)
      }
    }
  }
}

extension MultiSendCoordinator: KNListContactViewControllerDelegate {
  func listContactViewController(_ controller: KNListContactViewController, run event: KNListContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .select(let contact) = event {
        self.rootViewController.coordinatorDidSelectContact(contact)
      } else if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension MultiSendCoordinator: KNNewContactViewControllerDelegate {
  func newContactViewController(_ controller: KNNewContactViewController, run event: KNNewContactViewEvent) {
    self.navigationController.popViewController(animated: true) {
      if case .send(let address) = event {
        self.rootViewController.coordinatorSend(to: address)
      }
    }
  }
}

extension MultiSendCoordinator: MultiSendApproveViewControllerDelegate {

  func multiSendApproveVieController(_ controller: MultiSendApproveViewController, run event: MultiSendApproveViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
    case .dismiss:
      self.approveVC = nil
    
    case .approve(items: let items, isApproveUnlimit: let isApproveUnlimit, settings: let setting):
      guard case .real(let account) = self.session.wallet.type, let provider = self.session.externalProvider else {
        return
      }
      //TODO: send approve multiple token
      /*
       - Get gas price NGasCoordinator.shared.defaultKNGas
       - Get gas limit KNGasConfiguration.approveTokenGasLimitDefault
       */
      
      
      self.buildApproveDataList(items: items, isApproveUnlimit: isApproveUnlimit) { dataList in
        print(dataList)
      }
      
      
      
      if KNGeneralProvider.shared.isUseEIP1559 {
        
      } else {
        
      }
      
      controller.dismiss(animated: true) {
        self.rootViewController.coordinatorDidFinishApproveTokens()
      }
    }
  }

  fileprivate func getLatestNonce(completion: @escaping (Result<Int, AnyError>) -> Void) {
    guard let provider = self.session.externalProvider else {
      return
    }
    provider.getTransactionCount { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  fileprivate func buildApproveDataList(items: [MultiSendItem], isApproveUnlimit: Bool, completion: @escaping ([(MultiSendItem, Data)]) -> Void) {
    var dataList: [(MultiSendItem, Data)] = []
    let group = DispatchGroup()
    items.forEach { item in
      let value = isApproveUnlimit ? BigInt(2).power(256) - BigInt(1) : item.1
      let address = Address(string: Constants.multisendBscAddress)!
      group.enter()

      KNGeneralProvider.shared.getSendApproveERC20TokenEncodeData(networkAddress: address, value: value) { encodeResult in
        switch encodeResult {
        case .success(let data):
          dataList.append((item, data))
        case .failure( _):
          break
        }
        group.leave()
      }

      group.notify(queue: .global()) {
        completion(dataList)
      }
    }
  }
  
  
}

extension MultiSendCoordinator: GasFeeSelectorPopupViewControllerDelegate {
  func gasFeeSelectorPopupViewController(_ controller: GasFeeSelectorPopupViewController, run event: GasFeeSelectorPopupViewEvent) {
    switch event {
    case .infoPressed:
      break
    case .gasPriceChanged(let type, let value):
      self.approveVC?.coordinatorDidUpdateGasPriceType(type, value: value)
      self.confirmVC?.coordinatorDidUpdateGasPriceType(type, value: value)
    case .helpPressed(let tag):
      var message = "Gas.fee.is.the.fee.you.pay.to.the.miner".toBeLocalised()
      switch tag {
      case 1:
        message = "gas.limit.help".toBeLocalised()
      case 2:
        message = "max.priority.fee.help".toBeLocalised()
      case 3:
        message = "max.fee.help".toBeLocalised()
      default:
        break
      }
      self.navigationController.showBottomBannerView(
        message: message,
        icon: UIImage(named: "help_icon_large") ?? UIImage(),
        time: 10
      )
    case .updateAdvancedSetting(let gasLimit, let maxPriorityFee, let maxFee):
      self.approveVC?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
      self.confirmVC?.coordinatorDidUpdateAdvancedSettings(gasLimit: gasLimit, maxPriorityFee: maxPriorityFee, maxFee: maxFee)
    case .updateAdvancedNonce(let nonce):
      self.approveVC?.coordinatorDidUpdateAdvancedNonce(nonce)
      self.confirmVC?.coordinatorDidUpdateAdvancedNonce(nonce)
    default:
      break
    }
  }
}

extension MultiSendCoordinator: MultiSendConfirmViewControllerDelegate {
  func multiSendConfirmVieController(_ controller: MultiSendConfirmViewController, run event: MultiSendConfirmViewEvent) {
    switch event {
    case .openGasPriceSelect(let gasLimit, let baseGasLimit, let selectType, let advancedGasLimit, let advancedPriorityFee, let advancedMaxFee, let advancedNonce):
      openGasPriceSelectView(gasLimit, selectType, baseGasLimit, advancedGasLimit, advancedPriorityFee, advancedMaxFee, advancedNonce, controller)
    case .dismiss:
      self.confirmVC = nil
    case .confirm:
      break
    case .showAddresses(let items):
      self.openAddressListView(items: items, controller: controller)
    }
  }
}

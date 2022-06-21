//
//  AdvanceSearchTokenRouter.swift
//  KyberNetwork
//
//  Created Com1 on 13/06/2022.
//  Copyright © 2022 ___ORGANIZATIONNAME___. All rights reserved.
//
//  Template generated by Juanpe Catalán @JuanpeCMiOS
//

import UIKit
import Moya

class AdvanceSearchTokenRouter: AdvanceSearchTokenWireframeProtocol {
    
  weak var viewController: UIViewController?
  var coordinator: OverviewCoordinator?
  var pendingAction: (() -> Void)?
    
  func createModule(currencyMode: CurrencyMode, coordinator: OverviewCoordinator) -> UIViewController {
    // Change to get view from storyboard if not using progammatic UI
    let view = OverviewSearchTokenViewController()
    let interactor = AdvanceSearchTokenInteractor()
    let presenter = AdvanceSearchTokenPresenter(interface: view, interactor: interactor, router: self)
    presenter.currencyMode = currencyMode
    view.presenter = presenter
    interactor.presenter = presenter
    self.viewController = view
    self.coordinator = coordinator
    return view
  }
  
  func openChartTokenView(token: ResultToken, currencyMode: CurrencyMode) {
    let tokenModel = Token(name: token.name, symbol: token.symbol, address: token.id, decimals: token.decimals, logo: token.logo)
    let viewModel = ChartViewModel(token: tokenModel, currencyMode: currencyMode)
    viewModel.chainId = token.chainId
    let controller = ChartViewController(viewModel: viewModel)
    controller.delegate = self
    viewController?.navigationController?.pushViewController(controller, animated: true)
  }
  
  func showPopupSwitchChain(_ controller: ChartViewController, completion: @escaping () -> Void) {
    self.pendingAction = nil
    let popup = SwitchChainViewController()
    var newChain = KNGeneralProvider.shared.currentChain
    if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
      newChain = chainType
    }
    popup.selectedChain = newChain
    popup.nextButtonTitle = "Confirm"
    popup.completionHandler = { selected in
      KNGeneralProvider.shared.currentChain = selected
      var selectedAddress = ""
      if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
        selectedAddress = appDelegate.coordinator.session.wallet.addressString
      }
      KNNotificationUtil.postNotification(for: kChangeChainNotificationKey, object: selectedAddress)
      if selected == newChain {
        self.pendingAction = completion
      }
    }
    viewController?.present(popup, animated: true, completion: nil)
  }
  
  func appCoordinatorDidUpdateNewSession() {
    if let pendingAction = pendingAction {
      pendingAction()
    }
  }
}

extension AdvanceSearchTokenRouter: ChartViewControllerDelegate {
  func chartViewController(_ controller: ChartViewController, run event: ChartViewEvent) {
    switch event {
      case .getPoolList(address: let address, chainId: let chainId):
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.getPoolList(tokenAddress: address, chainId: chainId, limit: 10)) { result in
          switch result {
          case .failure(let error):
            controller.coordinatorFailUpdateApi(error)
          case .success(let resp):
            let decoder = JSONDecoder()
  //            do {
  //              let data = try decoder.decode(ChartDataResponse.self, from: resp.data)
  //              controller.coordinatorDidUpdateChartData(data.prices)
  //            } catch let error {
  //              print("[Debug]" + error.localizedDescription)
  //            }
          }
        }
      case .getChartData(let address, let from, _, let currency):
        var chainPath = KNGeneralProvider.shared.chainPath
        if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
          chainPath = chainType.chainPath()
        }
        let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
        provider.request(.getChartData(chainPath: chainPath, address: address, quote: currency, from: from)) { result in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(ChartDataResponse.self, from: resp.data)
            controller.coordinatorDidUpdateChartData(data.prices)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .getTokenDetailInfo(address: let address):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      
        var chainPath = KNGeneralProvider.shared.chainPath
        if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
          chainPath = chainType.chainPath()
        }
        
        provider.request(.getTokenDetail(chainPath: chainPath, address: address)) { (result) in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(TokenDetailResponse.self, from: resp.data)
            controller.coordinatorDidUpdateTokenDetailInfo(data.result)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .transfer(token: let token):
        var chainPath = KNGeneralProvider.shared.chainPath
        if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
          chainPath = chainType.chainPath()
        }
        if chainPath != KNGeneralProvider.shared.chainPath {
          let alertController = KNPrettyAlertController(
            title: "",
            message: Strings.pleaseSwitchTo + " \(chainPath.dropFirst().uppercased()) " + Strings.toSwap,
            secondButtonTitle: Strings.OK,
            firstButtonTitle: Strings.Cancel,
            secondButtonAction: {
              self.showPopupSwitchChain(controller) {
                self.coordinator?.openSendTokenView(token)
              }
            },
            firstButtonAction: nil
          )
          alertController.popupHeight = 300
          viewController?.present(alertController, animated: true, completion: nil)
        } else {
          self.coordinator?.openSendTokenView(token)
        }
    case .swap(token: let token):
      var chainPath = KNGeneralProvider.shared.chainPath
      if let chainType = ChainType.make(chainID: controller.viewModel.chainId) {
        chainPath = chainType.chainPath()
      }
      if chainPath != KNGeneralProvider.shared.chainPath {
        let alertController = KNPrettyAlertController(
          title: "",
          message: Strings.pleaseSwitchTo + " \(chainPath.dropFirst().uppercased()) " + Strings.toSwap,
          secondButtonTitle: Strings.OK,
          firstButtonTitle: Strings.Cancel,
          secondButtonAction: {
            self.showPopupSwitchChain(controller) {
              self.coordinator?.openSwapView(token: token, isBuy: true)
            }
          },
          firstButtonAction: nil
        )
        alertController.popupHeight = 300
        viewController?.present(alertController, animated: true, completion: nil)
      } else {
        //TODO: check màn hình swap đang bị reset lại thông tin token swap
        self.coordinator?.openSwapView(token: token, isBuy: true)
      }
    case .invest(token: let token):
      self.coordinator?.delegate?.overviewCoordinatorDidSelectDepositMore(tokenAddress: token.address)
    case .openEtherscan(address: let address):
      self.coordinator?.openCommunityURL("\(KNGeneralProvider.shared.customRPC.etherScanEndpoint)address/\(address)")
    case .openWebsite(url: let url):
      self.coordinator?.openCommunityURL(url)
    case .openTwitter(name: let name):
      self.coordinator?.openCommunityURL("https://twitter.com/\(name)/")
    case .getCandleChartData(address: let address, from: let from, to: let to, currency: let currency):
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      provider.request(.getTradingViewData(chainPath: String(KNGeneralProvider.shared.chainPath.dropFirst()), address: address, quote: currency, from: from * 1000)) { result in
        switch result {
        case .failure(let error):
          controller.coordinatorFailUpdateApi(error)
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(TradingViewChartResponse.self, from: resp.data)
            
            controller.coordinatorDidUpdateTradingViewData(data.data)
            print(data)
          } catch let error {
            print("[Debug]" + error.localizedDescription)
          }
        }
      }
    case .selectPool(source: let source, quote: let quote):
      break
    }
  }

}

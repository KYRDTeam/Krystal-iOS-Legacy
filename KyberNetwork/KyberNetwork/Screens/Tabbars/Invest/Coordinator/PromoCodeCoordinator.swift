//
//  PromoCodeCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import Foundation
import Moya
import KrystalWallets

class PromoCodeCoordinator: Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  
  var address: KAddress {
    return AppDelegate.session.address
  }
  
  lazy var rootViewController: PromoCodeListViewController = {
    let vm = PromoCodeListViewModel()
    let controller = PromoCodeListViewController(viewModel: vm)
    controller.delegate = self
    return controller
  }()
  
  var code: String?
  
  init(navigationController: UINavigationController = UINavigationController(), code: String? = nil) {
    self.code = code
    self.navigationController = navigationController
  }
  
  func start() {
    self.rootViewController.viewModel.searchText = code ?? ""
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
  }
  
  func stop() {
    
  }
}

extension PromoCodeCoordinator: PromoCodeListViewControllerDelegate {
  fileprivate func claimPromotionCode(_ code: String) {
    self.navigationController.displayLoading()
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
    provider.requestWithFilter(.claimPromotion(code: code, address: address.addressString)) { result in
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(ClaimResponse.self, from: resp.data)
          self.rootViewController.showSuccessTopBannerMessage(message: data.message)
          self.rootViewController.coordinatorDidClaimSuccessCode()
        } catch {
          do {
            let data = try decoder.decode(ClaimErrorResponse.self, from: resp.data)
            self.rootViewController.coordinatorDidReceiveClaimError(data.error)
          } catch {
            self.rootViewController.showErrorTopBannerMessage(message: "Can not decode data")
          }
        }
      case .failure(let error):
        self.rootViewController.showErrorTopBannerMessage(message: error.localizedDescription)
      }
      self.navigationController.hideLoading()
    }
  }
  
  func promoCodeListViewController(_ viewController: PromoCodeListViewController, run event: PromoCodeListViewEvent) {
    switch event {
    case .checkCode(let code):
      guard !code.isEmpty else {
        self.rootViewController.coordinatorDidUpdateSearchPromoCodeItems([], searchText: code)
        return
      }
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
      provider.requestWithFilter(.getPromotions(code: code, address: "")) { result in
        switch result {
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(PromotionResponse.self, from: resp.data)
            self.rootViewController.coordinatorDidUpdateSearchPromoCodeItems(data.codes, searchText: code)
          } catch {
            self.rootViewController.showErrorTopBannerMessage(message: "Can not decode data")
          }
        case .failure(let error):
          self.rootViewController.showErrorTopBannerMessage(message: error.localizedDescription)
        }
      }
    case .loadUsedCode:
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
      provider.requestWithFilter(.getPromotions(code: "", address: address.addressString)) { result in
        switch result {
        case .success(let resp):
          let decoder = JSONDecoder()
          do {
            let data = try decoder.decode(PromotionResponse.self, from: resp.data)
            self.rootViewController.coordinatorDidUpdateUsedPromoCodeItems(data.codes)
          } catch {
            self.rootViewController.showErrorTopBannerMessage(message: "Can not decode data")
          }
        case .failure(let error):
          self.rootViewController.showErrorTopBannerMessage(message: error.localizedDescription)
        }
      }
    case .claim(let code):
      claimPromotionCode(code)
    case .openDetail(item: let item):
      let vm = PromoCodeDetailViewModel(item: item)
      let controller = PromoCodeDetailViewController(viewModel: vm)
      controller.delegate = self
      self.navigationController.pushViewController(controller, animated: true, completion: nil)
    }
  }
}

extension PromoCodeCoordinator: PromoCodeDetailViewControllerDelegate {
  func promoCodeDetailViewController(_ controller: PromoCodeDetailViewController, claim code: String) {
    self.navigationController.popViewController(animated: true) {
      self.claimPromotionCode(code)
    }
  }
}

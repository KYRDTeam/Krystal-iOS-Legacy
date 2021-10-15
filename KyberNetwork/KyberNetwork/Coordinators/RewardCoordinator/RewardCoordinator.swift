//
//  RewardCoordinator.swift
//  KyberNetwork
//
//  Created by Com1 on 13/10/2021.
//

import UIKit
import Moya

class RewardCoordinator: Coordinator {
  fileprivate var session: KNSession
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  lazy var rootViewController: RewardsViewController = {
    let controller = RewardsViewController()
    return controller
  }()

  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true, completion: nil)
    loadRewards()
  }

  init(navigationController: UINavigationController = UINavigationController(), session: KNSession) {
    self.navigationController = navigationController
    self.session = session
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }

  func loadRewards() {
     let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
     let address = self.session.wallet.address.description
     provider.request(.getRewards(address: address)) { (result) in
       if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
         var rewardModels: [KNRewardModel] = []
         if let rewards = json["claimableRewards"] as? [JSONDictionary] {
           rewardModels = rewards.map({ item in
             return KNRewardModel(json: item)
           })
         }
         
         var rewardDetailModel: [KNRewardModel] = []
         if let rewardDetails = json["rewards"] as? [JSONDictionary] {
           rewardDetailModel = rewardDetails.map({ item in
             return KNRewardModel(json: item)
           })
         }
         
//         Storage.store(data.overview, as: self.session.wallet.address.description + Constants.referralOverviewStoreFileName)
         self.rootViewController.coordinatorDidUpdateRewards(rewards: rewardModels, rewardDetails: rewardDetailModel)
       } else {

       }
     }
   }
}

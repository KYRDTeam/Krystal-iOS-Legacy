//
//  AddWalletCoordinator.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 10/01/2023.
//

import Foundation
import BaseModule
import UIKit

class AddWalletCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    var rootViewController: AddWalletViewController
    var navigation: UINavigationController
    var parent: UIViewController
    
    init(parent: UIViewController, navigation: UINavigationController, delegate: AddWalletViewControllerDelegate) {
        self.parent = parent
        self.navigation = navigation
        self.rootViewController = AddWalletViewController()
        self.rootViewController.delegate = delegate
    }
    
    func start() {
        parent.present(self.navigation, animated: false) {
            self.navigation.pushViewController(self.rootViewController, animated: true)
        }
    }
}

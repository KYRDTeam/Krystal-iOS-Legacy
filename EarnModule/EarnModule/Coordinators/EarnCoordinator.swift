//
//  EarnCoordinator.swift
//  EarnModule
//
//  Created by Tung Nguyen on 08/12/2022.
//

import Foundation
import BaseModule
import UIKit

public class EarnModuleCoordinator: Coordinator {
    
    public var coordinators: [Coordinator] = []
    public private(set) var navigationController: UINavigationController
    var earnOverviewViewController: EarnOverviewController!
    
    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let viewModel = EarnOverViewModel()
        let viewController = EarnOverviewController.instantiateFromNib()
        viewController.viewModel = viewModel
        earnOverviewViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }
    
}

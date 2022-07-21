//
//  ErrorViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 24/06/2022.
//

import UIKit

class ErrorViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

  }

  @IBAction func backToHomeButtonTapped(_ sender: Any) {
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      self.dismiss(animated: true, completion: nil)
      appDelegate.coordinator.overviewTabCoordinator?.navigationController.tabBarController?.selectedIndex = 0
      appDelegate.coordinator.overviewTabCoordinator?.navigationController.popToRootViewController(animated: false)
    }
  }

}

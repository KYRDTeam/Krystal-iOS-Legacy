//
//  BaseViewController.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import Foundation
import UIKit

class BaseViewController: UIViewController {

  @IBOutlet weak var topBarHeight: NSLayoutConstraint?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    topBarHeight?.constant = UIScreen.statusBarHeight + 24 + 26 * 2
  }
  
}

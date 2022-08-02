//
//  SwapV2ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit

class SwapV2ViewController: KNBaseViewController {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var sourceTokenLabel: UILabel!
  @IBOutlet weak var destTokenLabel: UILabel!
  @IBOutlet weak var sourceBalanceLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  func configureViews() {
    
  }
  
}

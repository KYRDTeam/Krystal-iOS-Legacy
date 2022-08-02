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
  
  var viewModel: SwapV2ViewModel = SwapV2ViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  func configureViews() {
    setupTableView()
  }
  
  func setupTableView() {
    platformTableView.registerCellNib(SwapV2PlatformCell.self)
    platformTableView.delegate = self
    platformTableView.dataSource = self
  }
  
}

extension SwapV2ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return viewModel.platformRatesViewModels.count
    return 2
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwapV2PlatformCell.self, indexPath: indexPath)!
    cell.selectionStyle = .none
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 96
  }
  
}

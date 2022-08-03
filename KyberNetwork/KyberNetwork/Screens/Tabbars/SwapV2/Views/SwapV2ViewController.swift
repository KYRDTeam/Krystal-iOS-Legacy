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
  @IBOutlet weak var destViewHeight: NSLayoutConstraint!
  
  @IBOutlet weak var rateInfoView: SwapInfoView!
  @IBOutlet weak var slippageInfoView: SwapInfoView!
  @IBOutlet weak var minReceiveInfoView: SwapInfoView!
  @IBOutlet weak var gasFeeInfoView: SwapInfoView!
  @IBOutlet weak var maxGasFeeInfoView: SwapInfoView!
  @IBOutlet weak var priceImpactInfoView: SwapInfoView!
  @IBOutlet weak var routeInfoView: SwapInfoView!
  @IBOutlet weak var reloadRateImageView: UIImageView!
  @IBOutlet weak var sourceView: UIView!
  
  var viewModel: SwapV2ViewModel = SwapV2ViewModel()
  
  var numberOfRows = 0
  let platformRateItemHeight: CGFloat = 96
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  func configureViews() {
    setupInfoViews()
    setupTableView()
    setupRateLoadingView()
  }
  
  func setupRateLoadingView() {
    reloadRateImageView.image = UIImage(named: "progress_exclude")?.withRenderingMode(.alwaysTemplate)
    reloadRateImageView.tintColor = sourceView.backgroundColor
    reloadRateImageView.backgroundColor = .red
  }
  
  func setupInfoViews() {
    rateInfoView.setTitle(title: "Rate", underlined: false)
    slippageInfoView.setTitle(title: "Price Slippage", underlined: true)
    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)
    gasFeeInfoView.setTitle(title: "Gas Fee (est)", underlined: true)
    maxGasFeeInfoView.setTitle(title: "Max Gas Fee", underlined: true)
    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    routeInfoView.setTitle(title: "Route", underlined: true)
  }
  
  func setupTableView() {
    platformTableView.registerCellNib(SwapV2PlatformCell.self)
    platformTableView.delegate = self
    platformTableView.dataSource = self
    destViewHeight.constant = 112
  }
  
  @IBAction func continueWasTapped(_ sender: Any) {
//    numberOfRows += 1
    platformTableView.reloadData()
    
      self.priceImpactInfoView.isHidden = true
      self.routeInfoView.isHidden = true
    UIView.animate(withDuration: 0.5) {
      self.destViewHeight.constant = CGFloat(112) + CGFloat(self.numberOfRows) * self.platformRateItemHeight + 24
      self.view.layoutIfNeeded()
    }
    
    priceImpactInfoView.isHidden.toggle()
    routeInfoView.isHidden.toggle()
  }
  
  func showFetchingRatesAnimation() {
    
  }
  
  func onFetchedPlatformRates() {
    
  }
  
}

extension SwapV2ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return viewModel.platformRatesViewModels.count
    return numberOfRows
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

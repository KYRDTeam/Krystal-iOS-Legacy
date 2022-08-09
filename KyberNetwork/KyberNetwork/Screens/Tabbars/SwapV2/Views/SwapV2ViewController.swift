//
//  SwapV2ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit
import Lottie

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
  @IBOutlet weak var sourceView: UIView!
  @IBOutlet weak var rateLoadingView: CircularArrowProgressView!
  @IBOutlet weak var loadingView: UIView!
  @IBOutlet weak var expandIcon: UIImageView!
  @IBOutlet weak var sourceTextField: UITextField!
  @IBOutlet weak var fetchingAnimationView: AnimationView!
  
  @IBOutlet weak var sourceTokenView: UIView!
  @IBOutlet weak var destTokenView: UIView!
  var viewModel: SwapV2ViewModel = SwapV2ViewModel()
  
  let platformRateItemHeight: CGFloat = 96
  let loadingViewHeight: CGFloat = 142
  let rateReloadingInterval: Int = 30
  var timer: Timer?
  var remainingTime: Int = 0
  
  var isExpanded: Bool = false
  
  var canExpand: Bool = false {
    didSet {
      self.expandIcon.isHidden = !canExpand
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
    bindViewModel()
    resetTimer()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    rateLoadingView.startAnimation(duration: rateReloadingInterval)
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func configureViews() {
    setupAnimation()
    setupSourceView()
    setupInfoViews()
    setupTableView()
    setupRateLoadingView()
    setupDropdownView()
    setupSourceDestTokensView()
  }
  
  func setupAnimation() {
    fetchingAnimationView.animation = Animation.rocket
    fetchingAnimationView.contentMode = .scaleAspectFit
    fetchingAnimationView.loopMode = .loop
    fetchingAnimationView.play()
  }
  
  func setupSourceView() {
    sourceTextField.setPlaceholder(text: "0.00", color: .white.withAlphaComponent(0.5))
  }
  
  func setupDropdownView() {
    expandIcon.isUserInteractionEnabled = true
    expandIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onToggleExpand)))
  }
  
  func setupSourceDestTokensView() {
    sourceTokenView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSourceTokenSearch)))
    destTokenView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openDestTokenSearch)))
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
  
  func bindViewModel() {
    viewModel.platformRatesViewModels.observe(on: self) { [weak self] _ in
      self?.reloadRates()
    }
  }
  
  @IBAction func continueWasTapped(_ sender: Any) {
    priceImpactInfoView.isHidden.toggle()
    routeInfoView.isHidden.toggle()
  }
  
  @objc func onToggleExpand() {
    isExpanded.toggle()
    expandIcon.image = isExpanded ? Images.swapPullup : Images.swapDropdown
    let numberOfRows = viewModel.numberOfRateRows
    let rowsToShow = isExpanded ? numberOfRows : min(2, numberOfRows)
    UIView.animate(withDuration: 0.5) {
      self.destViewHeight.constant = CGFloat(112) + CGFloat(rowsToShow) * self.platformRateItemHeight + 24
      self.view.layoutIfNeeded()
    }
  }
  
  @objc func openSourceTokenSearch() {
    let controller = SearchTokenViewController(viewModel: SearchTokenViewModel())
    controller.isSourceToken = true
    controller.onSelectTokenCompletion = { selectedToken in
      print("THANGGG")
    }
    self.present(controller, animated: true, completion: nil)
  }
  
  @objc func openDestTokenSearch() {
    let controller = SearchTokenViewController(viewModel: SearchTokenViewModel())
    controller.isSourceToken = false
    controller.onSelectTokenCompletion = { selectedToken in
      print("THANGGG")
    }
    self.present(controller, animated: true, completion: nil)
  }
}

// MARK: Data
extension SwapV2ViewController {
  
  func reloadRates() {
    let numberOfRows = viewModel.numberOfRateRows
    let rowsToShow = isExpanded ? numberOfRows : min(2, numberOfRows)
    
    canExpand = numberOfRows > 2
    if !canExpand {
      isExpanded = false
    }
    platformTableView.reloadData()
    platformTableView.isHidden = false
    
    UIView.animate(withDuration: 0.5) {
      self.loadingView.isHidden = true
      self.destViewHeight.constant = CGFloat(112) + CGFloat(rowsToShow) * self.platformRateItemHeight + (rowsToShow > 0 ? 24.0 : 0.0)
      self.view.layoutIfNeeded()
    }
  }
  
  func showFetchingPlatformsAnimation() {
    loadingView.isHidden = false
  }
  
  func reloadDestView() {
    
  }
  
}

// MARK: Rate loading animation
extension SwapV2ViewController {
  
  func setupRateLoadingView() {
    remainingTime = rateReloadingInterval
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
      self?.onTimerTick()
    })
    rateLoadingView.isUserInteractionEnabled = true
    let reloadRateGesture = UITapGestureRecognizer(target: self, action: #selector(onTapReloadRate))
    rateLoadingView.addGestureRecognizer(reloadRateGesture)
  }
  
  @objc func onTapReloadRate() {
    resetTimer()
  }
  
  func onTimerTick() {
    remainingTime -= 1
    if remainingTime == 0 {
      resetTimer()
    } else {
      rateLoadingView.setRemainingTime(seconds: remainingTime)
    }
  }
  
  func resetTimer() {
    requestRates()
    remainingTime = rateReloadingInterval
    rateLoadingView.setRemainingTime(seconds: remainingTime)
    rateLoadingView.startAnimation(duration: rateReloadingInterval)
  }
  
  func requestRates() {
    UIView.animate(withDuration: 0.5) {
      self.expandIcon.isHidden = true
      self.loadingView.isHidden = false
      self.platformTableView.isHidden = true
      self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
    }
    viewModel.reloadRates()
  }
  
}

extension SwapV2ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.platformRatesViewModels.value.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwapV2PlatformCell.self, indexPath: indexPath)!
    cell.selectionStyle = .none
    cell.configure(viewModel: viewModel.platformRatesViewModels.value[indexPath.row])
    return cell
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 96
  }
  
}

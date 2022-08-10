//
//  SwapV2ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 02/08/2022.
//

import UIKit
import Lottie
import BigInt

class SwapV2ViewController: KNBaseViewController {
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var continueButton: UIButton!
  @IBOutlet weak var sourceTokenLabel: UILabel!
  @IBOutlet weak var destTokenLabel: UILabel!
  @IBOutlet weak var sourceBalanceLabel: UILabel!
  @IBOutlet weak var sourceTokenIcon: UIImageView!
  @IBOutlet weak var destBalanceLabel: UILabel!
  @IBOutlet weak var destTokenIcon: UIImageView!
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
  @IBOutlet weak var notFoundView: UIView!
  @IBOutlet weak var infoExpandButton: UIButton!
  @IBOutlet weak var infoSeparatorView: UIView!
  
  @IBOutlet weak var sourceTokenView: UIView!
  @IBOutlet weak var destTokenView: UIView!
  var viewModel: SwapV2ViewModel = SwapV2ViewModel()
  
  let platformRateItemHeight: CGFloat = 96
  let loadingViewHeight: CGFloat = 142
  let rateReloadingInterval: Int = 30
  var timer: Timer?
  var remainingTime: Int = 0
  
  var isExpanded: Bool = false {
    didSet {
      self.expandIcon.image = isExpanded ? Images.swapPullup : Images.swapDropdown
    }
  }
  
  var isInfoExpanded: Bool = false {
    didSet {
      UIView.animate(withDuration: 0.2) {
        self.infoExpandButton.setImage(self.isInfoExpanded ? Images.swapPullup : Images.swapDropdown, for: .normal)
        self.maxGasFeeInfoView.isHidden = !self.isInfoExpanded
        self.priceImpactInfoView.isHidden = !self.isInfoExpanded
      }
    }
  }
  
  var canExpand: Bool = false {
    didSet {
      self.expandIcon.isHidden = !canExpand
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
    resetViews()
    bindViewModel()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func configureViews() {
    setupButtons()
    setupAnimation()
    setupSourceView()
    setupInfoViews()
    setupTableView()
    setupRateLoadingView()
    setupDropdownView()
    setupSourceDestTokensView()
  }
  
  func resetViews() {
    rateInfoView.isHidden = true
    slippageInfoView.isHidden = true
    minReceiveInfoView.isHidden = true
    gasFeeInfoView.isHidden = true
    maxGasFeeInfoView.isHidden = true
    priceImpactInfoView.isHidden = true
    routeInfoView.isHidden = true
  }
  
  func setupAnimation() {
    fetchingAnimationView.animation = Animation.rocket
    fetchingAnimationView.contentMode = .scaleAspectFit
    fetchingAnimationView.loopMode = .loop
    fetchingAnimationView.play()
  }
  
  func setupButtons() {
    continueButton.setBackgroundColor(.Kyber.primaryGreenColor, forState: .normal)
    continueButton.setBackgroundColor(.Kyber.evenBg, forState: .disabled)
    continueButton.setTitleColor(.black, for: .normal)
    continueButton.setTitleColor(.white.withAlphaComponent(0.3), for: .disabled)
  }
  
  func setupSourceView() {
    sourceTextField.setPlaceholder(text: "0.00", color: .white.withAlphaComponent(0.5))
    sourceTextField.delegate = self
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
    
    slippageInfoView.setTitle(title: "Max Slippage", underlined: true)
    slippageInfoView.iconImageView.isHidden = true
    
    minReceiveInfoView.setTitle(title: "Min. Received", underlined: true)
    minReceiveInfoView.iconImageView.isHidden = true
    
    gasFeeInfoView.setTitle(title: "Network Fee (est)", underlined: true)
    gasFeeInfoView.iconImageView.isHidden = true
    
    maxGasFeeInfoView.setTitle(title: "Max Network Fee", underlined: true)
    maxGasFeeInfoView.iconImageView.isHidden = true
    
    priceImpactInfoView.setTitle(title: "Price Impact", underlined: true)
    priceImpactInfoView.iconImageView.isHidden = true
    
    routeInfoView.setTitle(title: "Route", underlined: true)
    routeInfoView.iconImageView.isHidden = true
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
    
    viewModel.sourceToken.observeAndFire(on: self) { [weak self] token in
      DispatchQueue.main.async {
        self?.sourceTokenLabel.text = token?.symbol
        self?.sourceTextField.text = nil
        if let token = token {
          self?.sourceTokenIcon.isHidden = false
          self?.sourceTokenIcon.setSymbolImage(symbol: token.symbol)
        } else {
          self?.sourceTokenIcon.isHidden = true
          self?.sourceTokenLabel.text = "Select Token"
        }
      }
    }
    
    viewModel.destToken.observeAndFire(on: self) { [weak self] token in
      DispatchQueue.main.async {
        self?.destTokenLabel.text = token?.symbol
        if let token = token {
          self?.destTokenIcon.isHidden = false
          self?.destTokenIcon.setSymbolImage(symbol: token.symbol)
        } else {
          self?.destTokenIcon.isHidden = true
          self?.destTokenLabel.text = "Select Token"
        }
      }
    }
    
    viewModel.sourceBalance.observeAndFire(on: self) { [weak self] balance in
      guard let self = self else { return }
      guard let sourceToken = self.viewModel.sourceToken.value else { return }
      let amount = balance ?? .zero
      let soureSymbol = sourceToken.symbol
      let decimals = sourceToken.decimals
      DispatchQueue.main.async {
        self.sourceBalanceLabel.text = "\(NumberFormatUtils.receivingAmount(value: amount, decimals: decimals)) \(soureSymbol)"
      }
    }
    
    viewModel.destBalance.observeAndFire(on: self) { [weak self] balance in
      guard let self = self else { return }
      guard let destToken = self.viewModel.destToken.value else { return }
      let destSymbol = destToken.symbol
      let decimals = destToken.decimals
      let amount = balance ?? .zero
      DispatchQueue.main.async {
        self.destBalanceLabel.text = "\(NumberFormatUtils.receivingAmount(value: amount, decimals: decimals)) \(destSymbol)"
      }
    }
    
    viewModel.rateString.observeAndFire(on: self) { [weak self] rate in
      self?.rateInfoView.setValue(value: rate, highlighted: false)
    }
    
    viewModel.slippageString.observeAndFire(on: self) { [weak self] string in
      self?.slippageInfoView.setValue(value: string, highlighted: true)
    }
    
    viewModel.minReceiveString.observeAndFire(on: self) { [weak self] string in
      self?.minReceiveInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.estimatedGasFeeString.observeAndFire(on: self) { [weak self] string in
      self?.gasFeeInfoView.setValue(value: string, highlighted: true)
    }
    
    viewModel.priceImpactString.observeAndFire(on: self) { [weak self] string in
      self?.priceImpactInfoView.setValue(value: string, highlighted: false)
    }
    
    viewModel.selectedPlatformRate.observeAndFire(on: self) { [weak self] rate in
      guard let self = self else { return }
      self.infoSeparatorView.isHidden = rate == nil
      self.rateInfoView.isHidden = rate == nil
      self.slippageInfoView.isHidden = rate == nil
      self.minReceiveInfoView.isHidden = rate == nil
      self.gasFeeInfoView.isHidden = rate == nil
      self.maxGasFeeInfoView.isHidden = rate == nil || !self.isInfoExpanded
      self.priceImpactInfoView.isHidden = rate == nil || !self.isInfoExpanded
    }
    
    viewModel.state.observeAndFire(on: self) { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .emptyAmount:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle("Enter an amount", for: .normal)
        self.rateLoadingView.isHidden = true
        self.platformTableView.isHidden = true
        self.notFoundView.isHidden = true
        self.loadingView.isHidden = true
        self.destViewHeight.constant = CGFloat(112)
        self.expandIcon.isHidden = true
      case .fetchingRates:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle("Fetching the best rates", for: .normal)
        self.platformTableView.isHidden = true
        self.notFoundView.isHidden = true
        self.loadingView.isHidden = false
        self.expandIcon.isHidden = true
        self.resetCountdownView()
        self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
      case .notConnected:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle("Connect Wallet", for: .normal)
        self.notFoundView.isHidden = true
        self.loadingView.isHidden = true
      case .rateNotFound:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle("Review Swap", for: .normal)
        self.rateLoadingView.isHidden = true
        self.platformTableView.isHidden = true
        self.notFoundView.isHidden = false
        self.loadingView.isHidden = true
        self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
      case .insufficientBalance:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle("Insufficient \(self.viewModel.sourceToken.value?.symbol ?? "") Balance", for: .normal)
        self.rateLoadingView.isHidden = true
        self.notFoundView.isHidden = true
        self.platformTableView.isHidden = true
        self.loadingView.isHidden = true
        self.destViewHeight.constant = CGFloat(112)
      case .checkingAllowance:
        self.continueButton.isEnabled = false
        self.continueButton.setTitle("Checking Allowance...", for: .normal)
        self.rateLoadingView.isHidden = false
        self.notFoundView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
      case .notApproved:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle("Approve \(self.viewModel.sourceToken.value?.symbol ?? "")", for: .normal)
        self.rateLoadingView.isHidden = false
        self.notFoundView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
      case .ready:
        self.continueButton.isEnabled = true
        self.continueButton.setTitle("Review Swap", for: .normal)
        self.rateLoadingView.isHidden = false
        self.notFoundView.isHidden = true
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
      }
    }
  }
  
  @IBAction func swapPairWasTapped(_ sender: Any) {
    viewModel.swapPair()
  }
  
  @IBAction func continueWasTapped(_ sender: Any) {
//    if let rate = self.viewModel.selectedPlatformRate.value {
//      let viewModel = SwapSummaryViewModel(currentRate: rate, srcToken: <#T##Token#>, srcAmount: <#T##BigInt#>, destToken: <#T##Token#>, destAmout: <#T##BigInt#>)
//      let summaryVC = SwapSummaryViewController(something: "")
//      self.present(summaryVC, animated: true)
//    }
  }
  
  @IBAction func infoExpandWasTapped(_ sender: Any) {
    self.isInfoExpanded.toggle()
  }
  
  @objc func onToggleExpand() {
    isExpanded.toggle()
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
    
    if rowsToShow > 0 {
      UIView.animate(withDuration: 0.5) {
        self.platformTableView.isHidden = false
        self.loadingView.isHidden = true
        self.notFoundView.isHidden = true
        self.destViewHeight.constant = CGFloat(112) + CGFloat(rowsToShow) * self.platformRateItemHeight + 24
        self.view.layoutIfNeeded()
      }
    } else {
      UIView.animate(withDuration: 0.5) {
        self.platformTableView.isHidden = true
        self.loadingView.isHidden = true
        if self.viewModel.isInputValid {
          self.notFoundView.isHidden = false
          self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
        } else {
          self.notFoundView.isHidden = true
          self.destViewHeight.constant = CGFloat(112)
        }
        self.view.layoutIfNeeded()
      }
    }
  }
  
  func showFetchingPlatformsAnimation() {
    loadingView.isHidden = false
  }
  
}

// MARK: Rate loading animation
extension SwapV2ViewController {
  
  func setupRateLoadingView() {
    rateLoadingView.isHidden = true
    remainingTime = rateReloadingInterval
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
      self?.onTimerTick()
    })
    rateLoadingView.isUserInteractionEnabled = true
    let reloadRateGesture = UITapGestureRecognizer(target: self, action: #selector(onTapReloadRate))
    rateLoadingView.addGestureRecognizer(reloadRateGesture)
  }
  
  @objc func onTapReloadRate() {
    resetCountdownView()
    viewModel.reloadRates()
  }
  
  func onTimerTick() {
    remainingTime -= 1
    if remainingTime == 0 {
      resetCountdownView()
      viewModel.reloadRates()
    } else {
      rateLoadingView.setRemainingTime(seconds: remainingTime)
    }
  }
  
  func resetCountdownView() {
    remainingTime = rateReloadingInterval
    rateLoadingView.setRemainingTime(seconds: remainingTime)
    rateLoadingView.startAnimation(duration: rateReloadingInterval)
    rateLoadingView.isHidden = !viewModel.isInputValid
  }
  
  func requestRates() {
    UIView.animate(withDuration: 0.5) {
      self.expandIcon.isHidden = true
      self.loadingView.isHidden = false
      self.platformTableView.isHidden = true
      self.notFoundView.isHidden = true
      self.destViewHeight.constant = CGFloat(112) + self.loadingViewHeight + 24
    }
    viewModel.reloadRates()
  }
  
  func onSourceAmountChange(value: String) {
    let doubleValue = Double(value) ?? 0
    viewModel.sourceAmountValue = doubleValue
  }
  
  func onSelectPlatformRateAt(index: Int) {
    viewModel.selectPlatform(platform: viewModel.platformRatesViewModels.value[index].rate.platform)
  }
  
}

extension SwapV2ViewController: UITextFieldDelegate {
  
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    onSourceAmountChange(value: textField.text ?? "")
    return true
  }
  
}

extension SwapV2ViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    isExpanded = false
    onSelectPlatformRateAt(index: indexPath.row)
  }
  
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

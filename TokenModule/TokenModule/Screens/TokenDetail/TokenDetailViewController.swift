//
//  ChartViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/24/21.
//

import UIKit
import BigInt
import MBProgressHUD
import Charts
import Dependencies
import BaseModule
import DesignSystem
import Services
import BaseWallet
import AppState

class TokenDetailViewController: KNBaseViewController {
  @IBOutlet weak var containScrollView: UIScrollView!
  @IBOutlet weak var chartContainerView: UIView!
  @IBOutlet var periodChartSelectButtons: [UIButton]!
  @IBOutlet weak var priceLabel: UILabel!
  @IBOutlet weak var priceDiffPercentageLabel: UILabel!
  @IBOutlet weak var priceDiffImageView: UIImageView!
  @IBOutlet weak var volumeLabel: UILabel!
  @IBOutlet weak var ethBalanceLabel: UILabel!
  @IBOutlet weak var usdBalanceLabel: UILabel!
  @IBOutlet weak var marketCapLabel: UILabel!
  @IBOutlet weak var atlLabel: UILabel!
  @IBOutlet weak var athLabel: UILabel!
  @IBOutlet weak var titleView: UILabel!
  @IBOutlet weak var transferButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!
  @IBOutlet weak var investButton: UIButton!
  @IBOutlet weak var descriptionTextView: GrowingTextView!
  @IBOutlet weak var chartDetailLabel: UILabel!
  @IBOutlet weak var favButton: UIButton!
  @IBOutlet weak var tagImageView: UIImageView!
  @IBOutlet weak var tagLabel: UILabel!
  @IBOutlet weak var tagLabelWidth: NSLayoutConstraint!
  @IBOutlet weak var addressToSuperViewLeading: NSLayoutConstraint!
  @IBOutlet weak var addressToSuperViewTrailing: NSLayoutConstraint!
  @IBOutlet weak var addressLeading: NSLayoutConstraint!
  @IBOutlet weak var tagView: UIView!
  @IBOutlet weak var chainView: UIView!
  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainAddressLabel: UILabel!
  @IBOutlet weak var infoSegment: SegmentedControl!
  @IBOutlet weak var aboutTitleLabel: UILabel!
  @IBOutlet weak var poolTableView: UITableView!
  @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
  @IBOutlet weak var poolViewTrailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var poolView: UIView!
  @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var showAllPoolButton: UIButton!
  @IBOutlet weak var poolNameContainerView: UIView!
  @IBOutlet weak var poolPairLabel: UILabel!
  @IBOutlet weak var poolNameLabel: UILabel!
  
  @IBOutlet weak var tradingView: TradingView!
  @IBOutlet weak var tokenChartView: LineChartView!
  @IBOutlet weak var poolChartContainer: UIView!
  @IBOutlet weak var tokenChartContainer: UIView!
  @IBOutlet weak var intervalStackview: UIStackView!
  @IBOutlet weak var chartHeight: NSLayoutConstraint!
  @IBOutlet weak var noDataImageView: UIImageView!
  
  @IBOutlet weak var socialButtonStackView: UIStackView!
  @IBOutlet weak var blockExploreButton: UIButton!
  @IBOutlet weak var websiteButton: UIButton!
  @IBOutlet weak var twitterButton: UIButton!
  @IBOutlet weak var discordButton: UIButton!
  @IBOutlet weak var telegramButton: UIButton!
  
  var viewModel: TokenDetailViewModel!
  fileprivate var tokenPoolTimer: Timer?

  var isSelectingLineChart: Bool = true {
    didSet {
      self.reloadCharts()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupConstraints()
    self.setupPoolInfoView()
    self.setupInfoSegment()
    self.setupTableView()
    self.setupTitle()
    self.setupButtons()
    self.setupChartViews()
    self.setupTradingView()
    self.bindViewModel()
    self.viewModel.loadChartData()
    self.reloadCharts()
    self.updateUISocialButtons()
  }
  
  func setupTradingView() {
    tradingView.delegate = self
  }
  
  func setupTitle() {
    self.titleView.attributedText = self.viewModel.headerTitle
  }
  
  func setupPoolInfoView() {
    self.updateUIPoolName(hidden: true)
  }
  
  func setupInfoSegment() {
    self.infoSegment.highlightSelectedSegment()
    self.infoSegment.frame = CGRect(x: self.infoSegment.frame.minX, y: self.infoSegment.frame.minY, width: self.infoSegment.frame.width, height: 40)
    self.infoSegment.selectedSegmentIndex = 0
  }
  
  func setupButtons() {
    self.updateUIPeriodSelectButtons()
    self.titleView.attributedText = self.viewModel.headerTitle
    self.transferButton.rounded(radius: 16)
    self.swapButton.rounded(radius: 16)
    self.investButton.rounded(radius: 16)
    self.favButton.setImage(self.viewModel.displayFavIcon, for: .normal)
    self.favButton.isHidden = self.viewModel.chainID != AppState.shared.currentChain.getChainId()
    periodChartSelectButtons.forEach { (button) in
      button.rounded(radius: 7)
    }
    if !self.viewModel.canEarn {
      self.investButton.removeFromSuperview()
      self.swapButton.rightAnchor.constraint(equalTo: self.swapButton.superview!.rightAnchor, constant: -26).isActive = true
    }
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(copyTokenAddress))
    self.chainAddressLabel.isUserInteractionEnabled = true
    self.chainAddressLabel.addGestureRecognizer(tapGesture)
  }

  func setupTableView() {
    self.poolTableView.registerCellNib(TokenPoolCell.self)
  }
  
  func setupChartViews() {
    
    tokenChartView.delegate = self

    tokenChartView.chartDescription.enabled = false
    tokenChartView.dragEnabled = true
    tokenChartView.setScaleEnabled(true)
    tokenChartView.pinchZoomEnabled = false
    tokenChartView.xAxis.labelTextColor = .white
    tokenChartView.xAxis.labelPosition = .bottom
    tokenChartView.leftAxis.labelTextColor = .white
    tokenChartView.rightAxis.enabled = false
    
    tokenChartView.xAxis.valueFormatter = DefaultAxisValueFormatter(block: { value, _ in
      let date = Date(timeIntervalSince1970: value * 0.001)
      let calendar = Calendar.current
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MMM dd"
      let hour = calendar.component(.hour, from: date)
      let minutes = calendar.component(.minute, from: date)
      let month = calendar.component(.month, from: date)
      let year = calendar.component(.year, from: date)
      switch self.viewModel.periodType {
      case .oneDay:
        return String(format: "%02d:%02d", hour, minutes)
      case .sevenDay:
        return dateFormatter.string(from: date)
      case .oneMonth, .threeMonth:
        return dateFormatter.string(from: date)
      case .oneYear:
        return "\(month)/\(year)"
      }
    })
    tokenChartView.animate(xAxisDuration: 2.5)
    
  }
  
  func reloadCharts() {
    tokenChartContainer.isHidden = !isSelectingLineChart
    poolChartContainer.isHidden = isSelectingLineChart
  }
  
  @objc func copyTokenAddress() {
    UIPasteboard.general.string = self.viewModel.token.address
    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = NSLocalizedString("copied", value: "Copied", comment: "")
    hud.hide(animated: true, afterDelay: 1.5)
    AppDependencies.tracker.track("token_detail_copy_address", properties: ["screenid": "token_detail"])
  }

  func setupConstraints() {
    topBarHeight?.constant = UIScreen.statusBarHeight + 36 * 2 + 24
    self.textViewLeadingConstraint.constant = UIScreen.main.bounds.size.width + 20
  }
  
  func updateUIPoolName(hidden: Bool) {
    self.poolNameContainerView.isHidden = hidden
    self.poolPairLabel.text = self.viewModel.selectedPoolPair
    self.poolNameLabel.text = self.viewModel.selectedPoolName
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    self.viewModel.loadPoolList()
    self.viewModel.loadTokenDetailInfo(isFirstLoad: true)
    self.updateUIChartInfo()
    self.updateUITokenInfo()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.tokenPoolTimer?.invalidate()
    self.tokenPoolTimer = nil
  }
  
  func bindViewModel() {
    viewModel.onTokenInfoUpdated = { [weak self] in
      self?.updateUITokenInfo()
      self?.updateUIChartInfo()
      self?.updateUISocialButtons()
    }
    viewModel.onTokenInfoLoadedFail = { [weak self] in
      // TODO: Show not found view
    }
    viewModel.onChartDataUpdated = { [weak self] in
      self?.noDataImageView.isHidden = self?.viewModel.chartData?.isEmpty == false
      self?.updateUIChartInfo()
      if let data = self?.viewModel.lineChartData {
        self?.tokenChartView.data = data
        self?.tokenChartView.setNeedsDisplay()
      }
    }
    viewModel.onPoolListUpdated = { [weak self] in
      guard let self = self else { return }
      if self.viewModel.poolData.isEmpty {
        self.infoSegment.isHidden = true
        self.aboutTitleLabel.isHidden = false
        self.hidePoolView(false)
        return
      }
      self.infoSegment.isHidden = false
      self.aboutTitleLabel.isHidden = true
      self.showAllPoolButton.isHidden = self.viewModel.poolData.count <= 5
      self.poolTableView.reloadData()
      self.updatePoolTableHeight()
    }
  }
  
  func showPoolView() {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      self.tableViewHeight.priority = .required
      self.poolViewTrailingConstraint.constant = 0
      self.textViewLeadingConstraint.constant = UIScreen.main.bounds.size.width + 20
      self.view.layoutIfNeeded()
    }
  }
  
  func hidePoolView(_ animate: Bool = true) {
    if animate {
      UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
        self.tableViewHeight.priority = .fittingSizeLevel
        self.poolViewTrailingConstraint.constant = UIScreen.main.bounds.size.width
        self.textViewLeadingConstraint.constant = 20
        self.view.layoutIfNeeded()
      }
    } else {
      self.tableViewHeight.priority = .fittingSizeLevel
      self.poolViewTrailingConstraint.constant = UIScreen.main.bounds.size.width
      self.textViewLeadingConstraint.constant = 20
      self.view.layoutIfNeeded()
    }
  }
  
  
  @IBAction func tradingViewBackWasTapped(_ sender: Any) {
    self.isSelectingLineChart = true
    self.viewModel.selectedPoolDetail = nil
    self.updateUIPoolName(hidden: true)
    self.poolTableView.reloadData()
  }
  
  @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    self.infoSegment.underlinePosition()
    if sender.selectedSegmentIndex == 1 {
      self.hidePoolView()
      AppDependencies.tracker.track("token_detail_about", properties: ["screenid": "token_detail"])
    } else {
      self.showPoolView()
      AppDependencies.tracker.track("token_detail_pools_show_all", properties: ["screenid": "token_detail"])
    }
  }

  @IBAction func changeChartPeriodButtonTapped(_ sender: UIButton) {
    guard let type = ChartPeriodType(rawValue: sender.tag), type != self.viewModel.periodType else {
      return
    }
    self.viewModel.periodType = type
    self.viewModel.loadChartData()
    self.updateUIPeriodSelectButtons()
    self.updateUITokenInfo()
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func transferButtonTapped(_ sender: UIButton) {
    AppDependencies.router.openTokenTransfer(token: viewModel.token)
    AppDependencies.tracker.track("token_detail_transfer", properties: ["screenid": "token_detail"])
  }
  
  @IBAction func swapButtonTapped(_ sender: UIButton) {
    AppDependencies.router.openSwap(token: viewModel.token)
    AppDependencies.tracker.track("token_detail_swap", properties: ["screenid": "token_detail"])
  }
  
  @IBAction func investButtonTapped(_ sender: UIButton) {
    AppDependencies.router.openInvest(token: viewModel.token)
    AppDependencies.tracker.track("token_detail_earn", properties: ["screenid": "token_detail"])
  }
  
  @IBAction func etherscanButtonTapped(_ sender: UIButton) {
    AppDependencies.router.openToken(address: viewModel.token.address, chainID: viewModel.chainID)
  }
  
  @IBAction func websiteButtonTapped(_ sender: UIButton) {
    guard let websiteURL = viewModel.detailInfo?.links.homepage else {
      return
    }
    AppDependencies.router.openExternalURL(url: websiteURL)
  }
  
  @IBAction func twitterButtonTapped(_ sender: UIButton) {
    guard let twitterName = viewModel.detailInfo?.links.twitterScreenName else {
      return
    }
    AppDependencies.router.openExternalURL(url: "https://twitter.com/\(twitterName)/")
  }
  
  @IBAction func dicordButtonTapped(_ sender: UIButton) {
    guard let discordURL = viewModel.detailInfo?.links.discord else {
      return
    }
    AppDependencies.router.openExternalURL(url: discordURL)
  }
  
  @IBAction func telegramButtonTapped(_ sender: UIButton) {
    guard let telegramURL = viewModel.detailInfo?.links.telegram else {
      return
    }
    AppDependencies.router.openExternalURL(url: telegramURL)
  }
  
  @IBAction func favButtonTapped(_ sender: UIButton) {
    AppDependencies.tokenStorage.markFavoriteToken(address: viewModel.token.address, toOn: !viewModel.isFaved)
    self.favButton.setImage(self.viewModel.displayFavIcon, for: .normal)
    AppDependencies.tracker.track("token_detail_favorite", properties: ["screenid": "token_detail"])
  }
  
  @IBAction func showAllPoolButtonTapped(_ sender: Any) {
    self.viewModel.isExpandingPoolTable = !self.viewModel.isExpandingPoolTable
    self.showAllPoolButton.setTitle(self.viewModel.isExpandingPoolTable ? .showLess : .showMore, for: .normal)
    self.updatePoolTableHeight()
  }

  fileprivate func updateUIChartInfo() {
    self.updateUIPeriodSelectButtons()
  }

  fileprivate func updateUITokenInfo() {
    self.titleView.attributedText = self.viewModel.headerTitle
    self.atlLabel.text = self.viewModel.displayAllTimeLow
    self.athLabel.text = self.viewModel.displayAllTimeHigh
    self.descriptionTextView.attributedText = self.viewModel.displayDescriptionAttribution
    self.priceLabel.text = self.viewModel.displayPrice
    self.volumeLabel.text = self.viewModel.display24hVol
    self.ethBalanceLabel.text = self.viewModel.diplayBalance
    self.usdBalanceLabel.text = self.viewModel.displayUSDBalance
    self.marketCapLabel.text = self.viewModel.displayMarketCap
    self.priceDiffPercentageLabel.text = self.viewModel.displayDiffPercent
    self.priceDiffPercentageLabel.textColor = self.viewModel.displayDiffColor
    self.priceDiffImageView.image = self.viewModel.diffImage
    self.swapButton.backgroundColor = self.viewModel.displayDiffColor
    self.transferButton.backgroundColor = self.viewModel.displayDiffColor
    if self.viewModel.canEarn {
      self.investButton.backgroundColor = self.viewModel.displayDiffColor
    }
    if let image = self.viewModel.tagImage {
      self.tagImageView.image = image
      self.tagLabel.text = self.viewModel.tagLabel
      self.tagLabelWidth.constant = self.viewModel.tagLabel.width(withConstrainedHeight: 28, font: UIFont.karlaReguler(ofSize: 12))
      self.addressToSuperViewLeading.isActive = false
      self.addressToSuperViewTrailing.constant = 100
      self.addressLeading.isActive = true
      self.tagView.isHidden = false
    } else {
      self.tagView.isHidden = true
      self.addressToSuperViewLeading.isActive = true
      let addressViewWidth = self.viewModel.token.address.shortTypeAddress.width(withConstrainedHeight: 28, font: UIFont.karlaReguler(ofSize: 12)) + 43
      let padding = (UIScreen.main.bounds.size.width - addressViewWidth) / 2
      self.addressToSuperViewLeading.constant = CGFloat(padding)
      self.addressToSuperViewTrailing.constant = CGFloat(padding)
      self.addressLeading.isActive = false
    }
    
    self.chainIcon.image = viewModel.chain.chainIcon()
    self.chainAddressLabel.text = self.viewModel.token.address.shortTypeAddress
  }

  fileprivate func updateUIPeriodSelectButtons() {
    self.periodChartSelectButtons.forEach { (button) in
      if button.tag == self.viewModel.periodType.rawValue {
        button.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
        button.backgroundColor = self.viewModel.displayDiffColor
      } else {
        button.setTitleColor(UIColor(named: "normalTextColor"), for: .normal)
        button.backgroundColor = .clear
      }
    }
  }
  
  func updatePoolTableHeight() {
    UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
      if self.viewModel.isExpandingPoolTable {
        self.tableViewHeight.constant = CGFloat(self.viewModel.poolData.count * 92)
      } else {
        self.tableViewHeight.constant = CGFloat(460)
      }
      self.view.layoutIfNeeded()
    }
  }
  
  func coordinatorDidUpdatePoolData(poolData: [TokenPoolDetail]) {
    if poolData.isEmpty {
      self.infoSegment.isHidden = true
      self.aboutTitleLabel.isHidden = false
      self.hidePoolView(false)
      return
    }
    self.infoSegment.isHidden = false
    self.aboutTitleLabel.isHidden = true
    self.viewModel.poolData = poolData
    self.showAllPoolButton.isHidden = poolData.count <= 5
    self.poolTableView.reloadData()
    self.updatePoolTableHeight()
  }

  func coordinatorDidUpdateChartData(_ data: [[Double]]) {
    self.noDataImageView.isHidden = !data.isEmpty
    self.viewModel.updateChartData(data)
    self.updateUIChartInfo()
    if let data = self.viewModel.lineChartData {
      self.tokenChartView.data = data
      self.tokenChartView.setNeedsDisplay()
    }
  }
  
  fileprivate func updateUISocialButtons() {
    guard let detail = self.viewModel.detailInfo else {
      self.socialButtonStackView.isHidden = true
      return
    }
    self.socialButtonStackView.isHidden = false
    
    if !detail.links.homepage.isValidURL, self.websiteButton != nil {
      self.websiteButton.removeFromSuperview()
    }
    
    if !detail.links.twitter.isValidURL, self.twitterButton != nil {
      self.twitterButton.removeFromSuperview()
    }
    
    if !detail.links.discord.isValidURL, self.discordButton != nil {
      self.discordButton.removeFromSuperview()
    }
    
    if !detail.links.telegram.isValidURL, self.telegramButton != nil {
      self.telegramButton.removeFromSuperview()
    }
  }
  
  func constructTradingViewLoadRequest(pool: TokenPoolDetail, fullscreen: Bool = false) -> ChartLoadRequest? {
    guard let chain = ChainType.allCases.first(where: { chain in
      chain.getChainId() == pool.chainId
    }) else { return nil }
    let source = pool.token0.address
    let quote = pool.token1.address
    return ChartLoadRequestBuilder()
      .symbol("\(pool.token0.symbol)/\(pool.token1.symbol)")
      .chain(chain.customRPC().apiChainPath)
      .baseAddress(source)
      .quoteAddress(quote)
      .period(.h1)
      .chartType(.candles)
      .apiURL(TokenModule.apiURL)
      .fullscreen(fullscreen)
      .build()
  }
  
  func reloadPoolTradingView(pool: TokenPoolDetail) {
    guard let request = constructTradingViewLoadRequest(pool: pool) else { return }
    tradingView.load(request: request)
  }
  
  func onSelectPool(pool: TokenPoolDetail) {
    if self.viewModel.selectedPoolDetail?.address == pool.address {
      return
    }
    self.viewModel.selectedPoolDetail = pool
    self.updateUIPoolName(hidden: false)
    self.poolTableView.reloadData()
    self.containScrollView.setContentOffset(CGPoint.zero, animated: true)
    self.reloadPoolTradingView(pool: pool)
  }
}

extension TokenDetailViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.poolData.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(TokenPoolCell.self, indexPath: indexPath)!
    let poolData = self.viewModel.poolData[indexPath.row]
    let isSelecting = poolData.address == viewModel.selectedPoolDetail?.address
    cell.updateUI(isSelecting: isSelecting, chain: viewModel.chain, poolDetail: poolData, baseTokenAddress: viewModel.baseTokenAddress, currencyMode: .usd)
    return cell
  }
}

extension TokenDetailViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if AppDependencies.featureFlag.isFeatureEnabled(key: "trading-view") {
      self.isSelectingLineChart = false
      let poolData = self.viewModel.poolData[indexPath.row]
      self.onSelectPool(pool: poolData)
      AppDependencies.tracker.track("token_detail_pair", properties: ["screenid": "token_detail", "pair": poolData.name])
    }
  }
  
}

extension TokenDetailViewController: TradingViewDelegate {
  
  func tradingView(_ tradingView: TradingView, handleAction action: TradingView.Action) {
    switch action {
    case .toggleFullscreen:
      self.openFullscreenTradingView()
    }
  }
  
  func openFullscreenTradingView() {
    guard let pool = viewModel.selectedPoolDetail else { return }
    guard let request = constructTradingViewLoadRequest(pool: pool, fullscreen: true) else { return }
    let vc = TradingViewController(request: request)
    vc.modalTransitionStyle = .crossDissolve
    vc.modalPresentationStyle = .overFullScreen
    self.present(vc, animated: true)
  }
}

extension TokenDetailViewController: ChartViewDelegate {
  func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
    print("[Chart] selected")
    self.chartDetailLabel.attributedText = self.viewModel.displayChartDetaiInfoAt(x: entry.x, y: entry.y)
  }
  
  func chartValueNothingSelected(_ chartView: ChartViewBase) {
    print("[Chart] Nothing selected")
  }
  
  func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
    print("[Chart] scale")
  }
  
  func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
    print("[Chart] translate")
  }
}

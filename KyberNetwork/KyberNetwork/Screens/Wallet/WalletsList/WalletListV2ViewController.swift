//
//  WalletListV2ViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/08/2022.
//

import UIKit
import KrystalWallets
import WalletConnectSwift
import AppState
import Dependencies

class WalletListV2ViewModel {
  var wallets: [KWallet] = []
  var watchAddresses: [KAddress] = []

  func reloadData() {
    wallets = WalletManager.shared.getAllWallets()
    watchAddresses = WalletManager.shared.watchAddresses()
  }
  
  func numberOfSection() -> Int {
    return 2
  }
  
  func numberOfRows(section: Int) -> Int {
    return section == 0 ? wallets.count : watchAddresses.count
  }
  
  func calculateHeight() -> CGFloat {
    let headerViewHeight = watchAddresses.isEmpty ? 0 : 45
    var section1Height: CGFloat = 0.0
    for index in 0..<numberOfRows(section: 0) {
      let wallet = wallets[index]
      let cellModel = RealWalletCellModel(wallet: wallet)
      section1Height += cellModel.isBackupedWallet() ? 83 : 60
    }

    let height = CGFloat(numberOfRows(section: 1) * 60 + headerViewHeight + 250) + section1Height
    return min(height, 600)
  }
}
 
class WalletListV2ViewController: KNBaseViewController, Coordinator {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet weak var connectWalletButton: UIButton!
  @IBOutlet weak var tapOutSideBackgroundView: UIView!
  @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
  
  var coordinators: [Coordinator] = []
  var passcodeCoordinator: KNPasscodeCoordinator?
  var currentWalletId: String?
  let transitor = TransitionDelegate()
  let viewModel: WalletListV2ViewModel
  var allowAllChainOption: Bool = false
  
  var onSelectWallet: ((KWallet) -> ())?
  var onSelectWatchAddress: ((KAddress) -> ())?
  
//  weak var delegate: WalletListV2ViewControllerDelegate?
  var currentAddress: KAddress {
    return AppDelegate.session.address
  }
  
  var currentChain: ChainType {
    return AppState.shared.currentChain
  }
  
  init() {
    viewModel = WalletListV2ViewModel()
    viewModel.reloadData()
    super.init(nibName: WalletListV2ViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  func start() {
    fatalError("Do not call this method")
  }
  
  deinit {
    unobserveNotifications()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    observeNotifications()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    tapOutSideBackgroundView.addGestureRecognizer(tapGesture)
    walletsTableView.registerCellNib(WalletCell.self)
    contentViewHeight.constant = viewModel.calculateHeight()
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
  
  func observeNotifications() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onWalletListUpdated),
      name: AppEventCenter.shared.kAppDidChangeAddress,
      object: nil
    )
  }
  
  func unobserveNotifications() {
    NotificationCenter.default.removeObserver(self, name: AppEventCenter.shared.kAppDidChangeAddress, object: nil)
  }
  
  @objc func onWalletListUpdated() {
    viewModel.reloadData()
    walletsTableView.reloadData()
  }

  @IBAction func connectWalletButtonTapped(_ sender: UIButton) {
    ScannerModule.start(previousScreen: ScreenName.explore, viewController: self, acceptedResultTypes: [.walletConnect], scanModes: [.qr]) { [weak self] text, type in
      guard let self = self else { return }
      switch type {
      case .walletConnect:
        AppEventCenter.shared.didScanWalletConnect(address: self.currentAddress, url: text)
      default:
        return
      }
    }
  }
  
  @IBAction func addWalletButtonTapped(_ sender: Any) {
    self.dismiss(animated: true) {
        AppDependencies.router.openAddWallet()
    }
  }

  @IBAction func manageWalletButtonTapped(_ sender: Any) {
    self.dismiss(animated: true) {
      AppDelegate.shared.coordinator.didSelectManageWallet()
    }
  }
  
  func showBackupWallet(walletId: String) {
    if let navigationController = self.navigationController {
      self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: navigationController, type: .verifyPasscode)
      self.passcodeCoordinator?.delegate = self
      self.passcodeCoordinator?.start()
    }
    self.currentWalletId = walletId
  }
  
  func openAddWallet() {
    guard let parent = UIApplication.shared.topMostViewController() else { return }
    let coordinator = KNAddNewWalletCoordinator(parentViewController: parent)
    coordinator.start(type: .full)
    coordinate(coordinator: coordinator)
  }
  
  func openAddWatchWallet() {
    guard let parent = UIApplication.shared.topMostViewController() else { return }
    let coordinator = AddWatchWalletCoordinator(parentViewController: parent, editingAddress: nil)
    coordinate(coordinator: coordinator)
  }
  
}

extension WalletListV2ViewController: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCreatePasscode(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator?.stop(completion: {
    })
  }

  func passcodeCoordinatorDidEvaluatePIN(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator?.stop {
      if let currentWalletId = self.currentWalletId {
        do {
          let mnemonic = try WalletManager.shared.exportMnemonic(walletID: currentWalletId)
          let seeds = mnemonic.split(separator: " ").map({ return String($0) })
          let viewModel = BackUpWalletViewModel(seeds: seeds, walletId: currentWalletId)
          let backUpVC = BackUpWalletViewController(viewModel: viewModel)
          backUpVC.delegate = self
          let navigation = UINavigationController(rootViewController: backUpVC)
          navigation.modalPresentationStyle = .fullScreen
          navigation.setNavigationBarHidden(true, animated: false)
          self.present(navigation, animated: true)
        } catch {
          print("Can not get seeds from account")
        }
      }
    }
  }

  func passcodeCoordinatorDidCancel(coordinator: KNPasscodeCoordinator) {
    self.passcodeCoordinator?.stop {
    }
  }
}

extension WalletListV2ViewController: BackUpWalletViewControllerDelegate {
  func didFinishBackup(_ controller: BackUpWalletViewController) {
    self.navigationController?.dismiss(animated: true, completion: {
      if let currentWalletId = self.currentWalletId {
        AppState.shared.markWalletBackedUp(walletID: currentWalletId)
      }
      self.viewModel.reloadData()
      self.walletsTableView.reloadData()
    })
  }
}

extension WalletListV2ViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return viewModel.numberOfSection()
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.numberOfRows(section: section)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(WalletCell.self, indexPath: indexPath)!
    var cellModel: WalletCellModel
    if indexPath.section == 0 {
      let wallet = viewModel.wallets[indexPath.row]
      cellModel = RealWalletCellModel(wallet: wallet)
      cell.didSelectBackup = {
        self.showBackupWallet(walletId: wallet.id)
        MixPanelManager.track("wallet_pop_up_backup", properties: ["screenid": "wallet_pop_up"])
      }
    } else {
      let kAddress = viewModel.watchAddresses[indexPath.row]
      cellModel = WatchWalletCellModel(address: kAddress)
    }

    cell.updateCell(cellModel)
    return cell
  }
  
}

extension WalletListV2ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.dismiss(animated: true) {
      if indexPath.section == 0 {
        let wallet = self.viewModel.wallets[indexPath.row]
        self.onSelectWallet?(wallet)
      } else {
        let kAddress = self.viewModel.watchAddresses[indexPath.row]
        self.onSelectWatchAddress?(kAddress)
      }
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return section == 0 ? 0 : 45
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 1 {
      let screenWidth = UIScreen.main.bounds.size.width
      let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 45))
      view.backgroundColor = UIColor.Kyber.popupBackgroundColor
      
      let seperatorView = UIView(frame: CGRect(x: 32, y: 0, width: screenWidth - 64, height: 1))
      seperatorView.backgroundColor = UIColor.Kyber.grayBackgroundColor
      view.addSubview(seperatorView)
      
      let label = UILabel(frame: CGRect(x: 32, y: 19, width: 74, height: 19))
      label.text = Strings.Watchlist
      label.textColor = UIColor.Kyber.whiteText
      label.font = UIFont.Kyber.bold(with: 16)
      view.addSubview(label)
      
      let plusButton = UIButton(frame: CGRect(x: screenWidth - 32 - 24, y: 0, width: 24, height: 24))
      plusButton.setImage(UIImage(named: "add_circle_grey"), for: .normal)
      plusButton.addAction(for: .touchUpInside) { [weak self] in
        self?.dismiss(animated: true) {
          self?.openAddWatchWallet()
        }
        MixPanelManager.track("wallet_pop_up_add_watchlist", properties: ["screenid": "wallet_pop_up"])
      }
      plusButton.center.y = label.center.y
      view.addSubview(plusButton)
      
      return view
    }
    return nil
  }
}

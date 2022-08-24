//
//  WalletListV2ViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 17/08/2022.
//

import UIKit
import KrystalWallets

class WalletListV2ViewModel {
  var wallets: [KWallet] = []
  var watchAddresses: [KAddress] = []

  func reloadData() {
    wallets = WalletManager.shared.getAllWallets()
    watchAddresses = WalletManager.shared.watchAddresses()
  }
}

class WalletListV2ViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet weak var connectWalletButton: UIButton!
  @IBOutlet weak var tapOutSideBackgroundView: UIView!
  var passcodeCoordinator: KNPasscodeCoordinator?
  var currentWalletId: String?
  let transitor = TransitionDelegate()
  let viewModel: WalletListV2ViewModel
  init() {
    viewModel = WalletListV2ViewModel()
    viewModel.reloadData()
    super.init(nibName: WalletListV2ViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    tapOutSideBackgroundView.addGestureRecognizer(tapGesture)
    walletsTableView.registerCellNib(WalletCell.self)
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func connectWalletButtonTapped(_ sender: UIButton) {
    
  }
  
  func showBackupWallet(walletId: String) {
    if let navigationController = self.navigationController {
      self.passcodeCoordinator = KNPasscodeCoordinator(navigationController: navigationController, type: .verifyPasscode)
      self.passcodeCoordinator?.delegate = self
      self.passcodeCoordinator?.start()
    }
    self.currentWalletId = walletId
  }
}

extension WalletListV2ViewController: KNPasscodeCoordinatorDelegate {
  func passcodeCoordinatorDidCreatePasscode() {
    self.passcodeCoordinator?.stop(completion: {
    })
  }

  func passcodeCoordinatorDidEvaluatePIN() {
    self.passcodeCoordinator?.stop {
      if let currentWalletId = self.currentWalletId {
        do {
          let mnemonic = try WalletManager.shared.exportMnemonic(walletID: currentWalletId)
          let seeds = mnemonic.split(separator: " ").map({ return String($0) })
          let viewModel = BackUpWalletViewModel(seeds: seeds)
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

  func passcodeCoordinatorDidCancel() {
    self.passcodeCoordinator?.stop {
    }
  }
}

extension WalletListV2ViewController: BackUpWalletViewControllerDelegate {
  func didFinishBackup(_ controller: BackUpWalletViewController) {
    self.navigationController?.dismiss(animated: true, completion: {
      if let currentWalletId = self.currentWalletId {
        WalletCache.shared.markWalletBackedUp(walletID: currentWalletId)
      }
      self.viewModel.reloadData()
      self.walletsTableView.reloadData()
    })
  }
}

extension WalletListV2ViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
//    let padding = KNGeneralProvider.shared.currentChain == .solana ? 125 : 179
//    return self.viewModel.walletTableViewHeight + CGFloat(padding)
    
    return 600
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension WalletListV2ViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(WalletCell.self, indexPath: indexPath)!
    let wallet = viewModel.wallets[indexPath.row]
    let cellModel = RealWalletCellModel(wallet: wallet)
    cell.updateCell(cellModel)
    cell.didSelectBackup = {
      self.showBackupWallet(walletId: wallet.id)
    }
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.wallets.count
  }
  
//  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//    return 60
//  }
}

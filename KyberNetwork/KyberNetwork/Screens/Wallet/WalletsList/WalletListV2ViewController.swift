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
  
  func numberOfSection() -> Int {
    return watchAddresses.isEmpty ? 1 : 2
  }
  
  func numberOfRows(section: Int) -> Int {
    return section == 0 ? wallets.count : watchAddresses.count
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
  
  @IBAction func addWalletButtonTapped(_ sender: Any) {
    
  }

  @IBAction func manageWalletButtonTapped(_ sender: Any) {
    
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
    
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return section == 0 ? 0 : 45
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 1 {
      let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 45))
      view.backgroundColor = UIColor.Kyber.popupBackgroundColor
      
      let seperatorView = UIView(frame: CGRect(x: 32, y: 0, width: UIScreen.main.bounds.size.width - 64, height: 1))
      seperatorView.backgroundColor = UIColor.Kyber.grayBackgroundColor
      view.addSubview(seperatorView)
      
      let label = UILabel(frame: CGRect(x: 32, y: 19, width: 74, height: 19))
      label.text = Strings.Watchlist
      label.textColor = UIColor.Kyber.whiteText
      label.font = UIFont.Kyber.bold(with: 16)
      view.addSubview(label)
      
      return view
    }
    return nil
  }
}

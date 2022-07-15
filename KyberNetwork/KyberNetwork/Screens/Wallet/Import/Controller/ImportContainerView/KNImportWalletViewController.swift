// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import QRCodeReaderViewController

enum ImportWalletChainType: Int {
  case multiChain = 0
  case evm
  case solana
}

enum ImportWalletType {
  case json
  case privateKey
  case seeds
}

enum KNImportWalletViewEvent {
  case back
  case importJSON(json: String, password: String, name: String?, importType: ImportWalletChainType, selectChain: ChainType)
  case importPrivateKey(privateKey: String, name: String?, importType: ImportWalletChainType, selectChain: ChainType)
  case importSeeds(seeds: [String], name: String?, importType: ImportWalletChainType, selectChain: ChainType)
  case sendRefCode(code: String)
}

protocol KNImportWalletViewControllerDelegate: class {
  func importWalletViewController(_ controller: KNImportWalletViewController, run event: KNImportWalletViewEvent)
}

class KNImportWalletViewController: KNBaseViewController {

  weak var delegate: KNImportWalletViewControllerDelegate?

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var headerContainerView: UIView!
  fileprivate var isViewSetup: Bool = false
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var jsonButton: UIButton!
  @IBOutlet weak var privateKeyButton: UIButton!
  @IBOutlet weak var seedsButton: UIButton!
  var currentImportWalletType: ImportWalletType = .json

  fileprivate var importJSONVC: KNImportJSONViewController?
  fileprivate var importPrivateKeyVC: KNImportPrivateKeyViewController?
  fileprivate var importSeedsVC: KNImportSeedsViewController?
  
  fileprivate var sourceVC: [UIViewController] = []
  
  var importType: ImportWalletChainType = .multiChain
  var selectedChainType: ChainType = KNGeneralProvider.shared.currentChain

  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isViewSetup {
      self.isViewSetup = true
      self.setupUI()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.jsonButton.centerVertically(padding: 10)
    self.privateKeyButton.centerVertically(padding: 10)
    self.seedsButton.centerVertically(padding: 10)

    let width: CGFloat = self.view.frame.width
    let height: CGFloat = self.view.frame.height - self.scrollView.frame.minY

    self.scrollView.contentSize = CGSize(
      width: CGFloat(self.sourceVC.count) * width,
      height: height
    )
    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: width,
      height: height
    )

    for index in 0..<self.sourceVC.count {
      let vc = self.sourceVC[index]
      vc.view.frame = CGRect(
        x: width * CGFloat(index),
        y: 0,
        width: width,
        height: height
      )
    }
  }

  fileprivate func setupUI() {
    self.setupImportTypeButtons()
    self.setupScrollView()
  }

  fileprivate func setupImportTypeButtons() {
    self.headerContainerView.rounded(radius: 30)
    self.navTitleLabel.text = "Import wallet".uppercased()
    self.navTitleLabel.addLetterSpacing()
    self.jsonButton.rounded(radius: 10.0)
    self.jsonButton.setBackgroundColor(UIColor(named: "importJsonSelectedColor")!, forState: .selected)
    self.jsonButton.setBackgroundColor(UIColor(named: "investButtonBgColor")!, forState: .normal)
    self.jsonButton.setBackgroundColor(UIColor(named: "buttonTextColor")!, forState: .disabled)
    self.jsonButton.setImage(UIImage(named: "json_import_icon"), for: .normal)
    self.jsonButton.setImage(UIImage(named: "json_import_select_icon"), for: .selected)
    self.jsonButton.setImage(UIImage(named: "json_import_icon_disable"), for: .disabled)
    self.jsonButton.setTitleColor(UIColor(named: "textWhiteColor"), for: .normal)
    self.jsonButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .selected)
    self.jsonButton.setTitleColor(UIColor(named: "navButtonBgColor"), for: .disabled)
    self.jsonButton.centerVertically(padding: 10)
    self.jsonButton.isEnabled = self.importType == .evm

    self.privateKeyButton.rounded(radius: 10.0)
    self.privateKeyButton.setBackgroundColor(UIColor(named: "importPKSelectedColor")!, forState: .selected)
    self.privateKeyButton.setBackgroundColor(UIColor(named: "investButtonBgColor")!, forState: .normal)
    self.privateKeyButton.setBackgroundColor(UIColor(named: "buttonTextColor")!, forState: .disabled)
    self.privateKeyButton.setImage(UIImage(named: "private_key_import_icon"), for: .normal)
    self.privateKeyButton.setImage(UIImage(named: "private_key_import_select_icon"), for: .selected)
    self.privateKeyButton.setImage(UIImage(named: "private_key_import_icon_disable"), for: .disabled)
    self.privateKeyButton.setTitle(
      NSLocalizedString("private.key", value: "Private Key", comment: ""),
      for: .normal
    )
    self.privateKeyButton.setTitleColor(UIColor(named: "textWhiteColor"), for: .normal)
    self.privateKeyButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .selected)
    self.privateKeyButton.setTitleColor(UIColor(named: "navButtonBgColor"), for: .disabled)
    self.privateKeyButton.centerVertically(padding: 10)
    self.privateKeyButton.isEnabled = self.importType != .multiChain

    self.seedsButton.rounded(radius: 10.0)
    self.seedsButton.setBackgroundColor(UIColor(named: "importSeedsSelectedColor")!, forState: .selected)
    self.seedsButton.setBackgroundColor(UIColor(named: "investButtonBgColor")!, forState: .normal)
    self.seedsButton.setImage(UIImage(named: "seeds_import_icon"), for: .normal)
    self.seedsButton.setImage(UIImage(named: "seeds_import_select_icon"), for: .selected)
    self.seedsButton.setTitleColor(UIColor(named: "textWhiteColor"), for: .normal)
    self.seedsButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .selected)
    self.seedsButton.centerVertically(padding: 10)
  }

  fileprivate func setupScrollView() {
    let width: CGFloat = self.view.frame.width
    let height: CGFloat = self.view.frame.height - self.scrollView.frame.minY
    self.scrollView.frame = CGRect(
      x: 0,
      y: self.scrollView.frame.minY,
      width: width,
      height: height
    )

    let importJSONVC: KNImportJSONViewController = {
      let controller = KNImportJSONViewController()
      controller.delegate = self
      return controller
    }()
    self.importJSONVC = importJSONVC
    let importPrivateKeyVC: KNImportPrivateKeyViewController = {
      let controller = KNImportPrivateKeyViewController()
      controller.delegate = self
      controller.importType = self.importType
      return controller
    }()
    self.importPrivateKeyVC = importPrivateKeyVC
    let importSeedsVC: KNImportSeedsViewController = {
      let controller = KNImportSeedsViewController()
      controller.delegate = self
      return controller
    }()
    self.importSeedsVC = importSeedsVC
    self.sourceVC = []
    if self.importType == .evm {
      self.sourceVC.append(importJSONVC)
    }
    if self.importType != .multiChain {
      self.sourceVC.append(importPrivateKeyVC)
    }
    self.sourceVC.append(importSeedsVC)

    self.scrollView.contentSize = CGSize(
      width: CGFloat(self.sourceVC.count) * width,
      height: height
    )
    self.scrollView.delegate = self
    for id in 0..<self.sourceVC.count {
      let viewController = self.sourceVC[id]
      self.addChild(viewController)
      self.scrollView.addSubview(viewController.view)
      let originX: CGFloat = CGFloat(id) * width
      viewController.view.frame = CGRect(
        x: originX,
        y: 0,
        width: width,
        height: height
      )
      viewController.didMove(toParent: self)
    }
    self.updateDefaultPage()
  }

  func resetUIs() {
    self.importJSONVC?.resetUIs()
    self.importPrivateKeyVC?.resetUI()
    self.importSeedsVC?.resetUIs()
    self.updateDefaultPage()
  }

  @IBAction func importTypeButtonPressed(_ sender: UIButton) {
    switch sender.tag {
    case 0:
      self.currentImportWalletType = .json
      self.updateUIWithCurrentPage(0)
    case 1:
      self.currentImportWalletType = .privateKey
      if self.importType == .solana {
        self.updateUIWithCurrentPage(0)
      } else {
        self.updateUIWithCurrentPage(1)
      }
    default:
      self.currentImportWalletType = .seeds
      if self.importType == .multiChain {
        self.updateUIWithCurrentPage(0)
      } else if self.importType == .solana {
        self.updateUIWithCurrentPage(1)
      } else {
        self.updateUIWithCurrentPage(2)
      }
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.importWalletViewController(self, run: .back)
  }
  
  fileprivate func updateDefaultPage() {
    self.updateUIWithCurrentPage(0)
  }

  fileprivate func updateUIWithCurrentPage(_ page: Int) {
    self.view.endEditing(true)
    UIView.animate(withDuration: 0.15) {
      self.jsonButton.isSelected = false
      self.privateKeyButton.isSelected = false
      self.seedsButton.isSelected = false
      let vc = self.sourceVC[page]
      if vc == self.importJSONVC {
        self.jsonButton.isSelected = true
      } else if vc == self.importPrivateKeyVC {
        self.privateKeyButton.isSelected = true
      } else {
        self.seedsButton.isSelected = true
      }
      let x = CGFloat(page) * self.scrollView.frame.size.width
      self.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func openQRCode() {
    let qrcode = QRCodeReaderViewController()
    qrcode.delegate = self
    self.present(qrcode, animated: true, completion: nil)
  }
}

extension KNImportWalletViewController: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
    self.updateUIWithCurrentPage(Int(pageNumber))
  }
}

extension KNImportWalletViewController: KNImportJSONViewControllerDelegate {
  func importJSONControllerDidSelectQRCode(controller: KNImportJSONViewController) {
    self.openQRCode()
  }
  
  func importJSONViewController(controller: KNImportJSONViewController, send refCode: String) {
    self.delegate?.importWalletViewController(self, run: .sendRefCode(code: refCode))
  }
  
  func importJSONViewControllerDidPressNext(sender: KNImportJSONViewController, json: String, password: String, name: String?) {
    self.delegate?.importWalletViewController(
      self,
      run: .importJSON(json: json, password: password, name: name, importType: self.importType, selectChain: self.selectedChainType)
    )
    let json: JSONDictionary = ["json": json, "password": password]
    KNNotificationUtil.postNotification(for: "notification", object: nil, userInfo: json)
  }
}

extension KNImportWalletViewController: KNImportPrivateKeyViewControllerDelegate {
  func importPrivateKeyControllerDidSelectQRCode(controller: KNImportPrivateKeyViewController) {
    self.openQRCode()
  }
  
  func importPrivateKeyViewController(controller: KNImportPrivateKeyViewController, send refCode: String) {
    self.delegate?.importWalletViewController(self, run: .sendRefCode(code: refCode))
  }
  
  func importPrivateKeyViewControllerDidPressNext(sender: KNImportPrivateKeyViewController, privateKey: String, name: String?) {
    self.delegate?.importWalletViewController(
      self,
      run: .importPrivateKey(privateKey: privateKey, name: name, importType: self.importType, selectChain: self.selectedChainType)
    )
  }
}

extension KNImportWalletViewController: KNImportSeedsViewControllerDelegate {
  func importSeedsViewControllerDidSelectQRCode(controller: KNImportSeedsViewController) {
    self.openQRCode()
  }
  
  func importSeedsViewController(controller: KNImportSeedsViewController, send refCode: String) {
    self.delegate?.importWalletViewController(self, run: .sendRefCode(code: refCode))
  }
  
  func importSeedsViewControllerDidPressNext(sender: KNImportSeedsViewController, seeds: [String], name: String?) {
    self.delegate?.importWalletViewController(self, run: .importSeeds(seeds: seeds, name: name, importType: self.importType, selectChain: self.selectedChainType))
  }
}

extension KNImportWalletViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.importJSONVC?.containerViewDidUpdateRefCode(result)
      self.importSeedsVC?.containerViewDidUpdateRefCode(result)
      self.importPrivateKeyVC?.containerViewDidUpdateRefCode(result)
    }
  }
}

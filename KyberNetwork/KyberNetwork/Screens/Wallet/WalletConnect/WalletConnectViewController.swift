//
//  WalletConnectRequestViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 29/09/2022.
//

import UIKit
import WalletConnectSwift
import KrystalWallets
import Web3

class WalletConnectViewController: UIViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var appLogoImageView: UIImageView!
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var walletNameLabel: UILabel!
  @IBOutlet weak var walletAddressLabel: UILabel!
  @IBOutlet weak var primaryButton: UIButton!
  @IBOutlet weak var secondaryButton: UIButton!
  
  @IBOutlet weak var requestView: UIView!
  @IBOutlet weak var statusView: UIView!
  
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var statusIconImageView: UIImageView!
  
  @IBOutlet weak var connectedDappIcon: UIImageView!
  @IBOutlet weak var connectedDappName: UILabel!
  @IBOutlet weak var connectedDappURLLabel: UILabel!
  @IBOutlet weak var connectedWalletAddressLabel: UILabel!
  @IBOutlet weak var connectedView: UIView!
  
  var url: WCURL!
  var address: KAddress!
  var server: Server!
  var privateKey: EthereumPrivateKey?
  var session: Session?
  var lastTimeRequest: Date?
  var detected: Bool = false
  var startSessionAction: ((Session.WalletInfo) -> Void)?
  
  enum State {
    case requesting
    case detected
    case connecting
    case failed
    case connected
  }
  
  var state: State = .requesting {
    didSet {
      DispatchQueue.main.async {
        self.updateUI()
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()
    updateUI()
    initPrivateKey()
    setupServer()
    connect()
  }
  
  func setupView() {
    avatarImageView.image = UIImage.generateImage(with: 32, hash: address.addressString.dataFromHex() ?? Data())
    walletNameLabel.text = address.name
    walletAddressLabel.text = address.addressString
  }
  
  func initPrivateKey() {
    if let hexPrivateKey = try? WalletManager.shared.exportPrivateKey(address: address), let privateKey = try? EthereumPrivateKey(hexPrivateKey: hexPrivateKey) {
      self.privateKey = privateKey
    }
  }
  
  func setupServer() {
    server = Server(delegate: self)
    if let privateKey = privateKey {
      server.register(handler: PersonalSignHandler(for: self, server: server, privateKey: privateKey, session: AppDelegate.session))
      server.register(handler: SignTransactionHandler(for: self, server: server, privateKey: privateKey, session: AppDelegate.session))
      server.register(handler: SendTransactionHandler(for: self, server: server, privateKey: privateKey, session: AppDelegate.session))
    }
  }
  
  func connect() {
    state = .requesting
    try! server.connect(to: url)
    Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in
      if !(self?.detected ?? false) {
        self?.state = .failed
      }
    }
  }
  
  func updateUI() {
    switch state {
    case .requesting, .connecting:
      statusLabel.text = Strings.wcConnectingDapp
      statusIconImageView.image = Images.connectSuccess
      primaryButton.setTitle(Strings.wcCancel, for: .normal)
      primaryButton.setTitleColor(.white.withAlphaComponent(0.95), for: .normal)
      primaryButton.setBackgroundColor(.Kyber.cellBackground, forState: .normal)
      secondaryButton.isHidden = true
      requestView.isHidden = true
      statusView.isHidden = false
      connectedView.isHidden = true
    case .failed:
      statusLabel.text = Strings.wcConnectingFailed
      statusIconImageView.image = Images.connectFailed
      primaryButton.setTitle(Strings.wcTryAgain, for: .normal)
      primaryButton.setTitleColor(.Kyber.buttonText, for: .normal)
      primaryButton.setBackgroundColor(.Kyber.buttonBg, forState: .normal)
      secondaryButton.isHidden = false
      requestView.isHidden = true
      statusView.isHidden = false
      connectedView.isHidden = true
    case .detected:
      connectedView.isHidden = true
      statusView.isHidden = true
      requestView.isHidden = false
      primaryButton.setTitle(Strings.wcConnect, for: .normal)
      primaryButton.setTitleColor(.Kyber.buttonText, for: .normal)
      primaryButton.setBackgroundColor(.Kyber.buttonBg, forState: .normal)
      secondaryButton.isHidden = false
      appLogoImageView.kf.setImage(with: session?.dAppInfo.peerMeta.icons.last)
      titleLabel.text = String(format: Strings.wcConnectMessage, session?.dAppInfo.peerMeta.name ?? "")
    case .connected:
      connectedView.isHidden = false
      requestView.isHidden = true
      statusView.isHidden = true
      connectedDappIcon.kf.setImage(with: session?.dAppInfo.peerMeta.icons.last)
      connectedDappName.text = session?.dAppInfo.peerMeta.name
      connectedDappURLLabel.text = session?.dAppInfo.peerMeta.url.absoluteString
      connectedWalletAddressLabel.text = address.addressString
    }
  }
  
  @IBAction func primaryButtonWasTapped(_ sender: Any) {
    switch state {
    case .requesting, .connecting:
      dismiss(animated: true)
    case .failed:
      connect()
    case .detected:
      guard let privateKey = privateKey else { return }
      let walletMeta = Session.ClientMeta(name: "Test Wallet",
                                          description: nil,
                                          icons: [],
                                          url: URL(string: "https://safe.gnosis.io")!)
      let walletInfo = Session.WalletInfo(approved: true,
                                          accounts: [privateKey.address.hex(eip55: true)],
                                          chainId: KNGeneralProvider.shared.customRPC.chainID,
                                          peerId: UUID().uuidString,
                                          peerMeta: walletMeta)
      startSessionAction?(walletInfo)
    case .connected:
      ()
    }
  }
  
  @IBAction func cancelButtonWasTapped(_ sender: Any) {
    self.dismiss(animated: true)
  }
  
  @IBAction func disconnectWasTapped(_ sender: Any) {
    guard let session = session else { return }
    showConfirmAlert(title: Strings.wcDisconnect, message: Strings.wcDisconnectConfirm) { [weak self] in
      try? self?.server.disconnect(from: session)
      self?.dismiss(animated: true)
    }
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    switch state {
    case .connected:
      guard let session = session else {
        self.dismiss(animated: true)
        return
      }
      showConfirmAlert(title: Strings.wcDisconnect, message: Strings.wcDisconnectConfirm) { [weak self] in
        try? self?.server.disconnect(from: session)
        self?.dismiss(animated: true)
      }
    default:
      self.dismiss(animated: true)
    }
  }
  
}

extension WalletConnectViewController: ServerDelegate {
  
  func server(_ server: Server, didFailToConnect url: WCURL) {
    state = .failed
  }
  
  func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
    self.detected = true
    self.session = session
    self.state = .detected
    self.startSessionAction = completion
  }
  
  func server(_ server: Server, didConnect session: Session) {
    self.session = session
    self.state = .connected
  }
  
  func server(_ server: Server, didDisconnect session: Session) {
    
  }
  
  func server(_ server: Server, didUpdate session: Session) {
    
  }
  
}

// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt
import QRCodeReaderViewController
import Starscream
import Web3Core
import WalletConnectSwift
import KrystalWallets

class KNWalletConnectViewController: KNBaseViewController {
  
  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var logoImageView: UIImageView!
  @IBOutlet weak var nameTextLabel: UILabel!
  @IBOutlet weak var connectionStatusLabel: UILabel!
  
  @IBOutlet weak var connectedToTextLabel: UILabel!
  @IBOutlet weak var urlLabel: UILabel!
  @IBOutlet weak var addressTextLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  
  var server: Server!
  var session: Session!
  var privateKey: EthereumPrivateKey!
  
  let sessionKey = "sessionKey"
  var wcURL: WCURL!
  var isConnected = false
  var disconnectAfterDisappear = true
  let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
  
  var appSession: KNSession {
    return AppDelegate.session
  }
  
  init(wcURL: WCURL, pk: String) {
    self.wcURL = wcURL
    self.privateKey = try! EthereumPrivateKey(privateKey: .init(hex: pk))
    super.init(nibName: KNWalletConnectViewController.className, bundle: nil)
    self.configureServer()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    DispatchQueue.global(qos: .background).async {
      self.connectToWC()
    }
    
    let address = appSession.address.addressString
    self.addressLabel.text = "\(address.prefix(12))...\(address.suffix(10))"
    self.urlLabel.text = ""
    self.connectionStatusLabel.text = ""
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateUIConnectStatusLabel()
    self.updateWCInfo()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if self.disconnectAfterDisappear {
      self.disconnectWC()
    }
  }
  
  private func configureServer() {
    server = Server(delegate: self)
    server.register(handler: PersonalSignHandler(for: self, server: server, privateKey: privateKey, session: self.appSession))
    server.register(handler: SignTransactionHandler(for: self, server: server, privateKey: privateKey, session: self.appSession))
    server.register(handler: SendTransactionHandler(for: self, server: server, privateKey: privateKey, session: self.appSession))
  }
  
  func connectToWC() {
    do {
      try self.server.connect(to: self.wcURL)
    } catch {
      return
    }
  }
  
  func disconnectWC() {
    guard self.isConnected else {
      return
    }
    try! server.disconnect(from: session)
  }
  
  func onMainThread(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
      closure()
    } else {
      DispatchQueue.main.async {
        closure()
      }
    }
  }
  
  func updateWCInfo() {
    guard self.isViewLoaded, self.isConnected else {
      return
    }
    if let url = session.dAppInfo.peerMeta.icons.first {
      self.logoImageView.setImage(with: url, placeholder: nil)
    }
    self.urlLabel.text = session.dAppInfo.peerMeta.url.absoluteString
    self.nameTextLabel.text = session.dAppInfo.peerMeta.name
  }
  
  func connectionStatusUpdated(_ connected: Bool) {
    self.isConnected = connected
    guard self.isViewLoaded else {
      return
    }
    self.updateUIConnectStatusLabel()
  }
  
  func updateUIConnectStatusLabel() {
    self.connectionStatusLabel.text = self.isConnected ? "Online" : "Offline"
    self.connectionStatusLabel.textColor = self.isConnected ? UIColor.Kyber.green : UIColor.Kyber.red
  }
  
  @IBAction func backButtonPressed(_ sender: Any) {
    if !self.isConnected {
      self.dismiss(animated: true, completion: nil)
      return
    }
    
    let alert = UIAlertController(title: "Disconnect session?", message: "Do you want to disconnect this session?", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction(title: "Disconnect", style: .default, handler: { _ in
      self.disconnectWC()
      self.dismiss(animated: true, completion: nil)
    }))
    self.present(alert, animated: true, completion: nil)
  }
  
  func getLatestNonce(completion: @escaping (Int) -> Void) {
    web3Service.getTransactionCount(for: appSession.address.addressString) { result in
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }
}

extension Response {
  static func signature(_ signature: String, for request: Request) -> Response {
    return try! Response(url: request.url, value: signature, id: request.id!)
  }
}

class BaseHandler: RequestHandler {
  weak var controller: UIViewController!
  weak var sever: Server!
  weak var privateKey: EthereumPrivateKey!
  weak var session: KNSession!
  let web3Service = EthereumWeb3Service(chain: KNGeneralProvider.shared.currentChain)
  
  init(for controller: UIViewController, server: Server, privateKey: EthereumPrivateKey, session: KNSession) {
    self.controller = controller
    self.sever = server
    self.privateKey = privateKey
    self.session = session
  }
  
  func canHandle(request: Request) -> Bool {
    return false
  }
  
  func handle(request: Request) {
    // to override
  }
  
  func askToSign(request: Request, message: String, sign: @escaping () -> String) {
    let onSign = {
      let signature = sign()
      self.sever.send(.signature(signature, for: request))
    }
    let onCancel = {
      self.sever.send(.reject(request))
    }
    DispatchQueue.main.async {
      UIAlertController.showShouldSign(from: self.controller,
                                       title: "Request to sign a message",
                                       message: message,
                                       onSign: onSign,
                                       onCancel: onCancel)
    }
  }
  
  func askToAsyncSign(request: Request, message: String, sign: @escaping () -> Void) {
    let onSign = {
      sign()
    }
    let onCancel = {
      self.sever.send(.reject(request))
    }
    DispatchQueue.main.async {
      UIAlertController.showShouldSign(from: self.controller,
                                       title: "Request to sign a message",
                                       message: message,
                                       onSign: onSign,
                                       onCancel: onCancel)
    }
  }
  
  func getLatestNonce(completion: @escaping (Int) -> Void) {
    web3Service.getTransactionCount(for: session.address.addressString) { result in
      switch result {
      case .success(let res):
        completion(res)
      case .failure:
        self.getLatestNonce(completion: completion)
      }
    }
  }
  
  func buildSignTransaction(dict: [String: String], nonce: Int, gasPrice: BigInt) -> SignTransaction? {
    guard
      let gasLimit = BigInt(dict["gas"]?.drop0x ?? "", radix: 16),
      let value = BigInt(dict["value"]?.drop0x ?? "", radix: 16),
      let to = dict["to"]
    else
    {
      return nil
    }
    let data = Data(Array<UInt8>(hex: dict["data"]?.drop0x ?? ""))
    
    return SignTransaction(
      value: value,
      address: session.address.addressString,
      to: to,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
  }
}

class PersonalSignHandler: BaseHandler {
  override func canHandle(request: Request) -> Bool {
    return request.method == "personal_sign"
  }
  
  override func handle(request: Request) {
    do {
      let messageBytes = try request.parameter(of: String.self, at: 0)
      let address = try request.parameter(of: String.self, at: 1)
      
      guard address.lowercased() == privateKey.address.hex(eip55: true).lowercased() else {
        sever.send(.reject(request))
        return
      }
      
      let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes
      
      askToSign(request: request, message: decodedMessage) {
        let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
        let (v, r, s) = try! self.privateKey.sign(message: .init(hex: personalMessageData.toHexString()))
        return "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16) // v in [0, 1]
      }
    } catch {
      sever.send(.invalid(request))
      return
    }
  }
  
  private func personalMessageData(messageData: Data) -> Data {
    let prefix = "\u{19}Ethereum Signed Message:\n"
    let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
    return prefixData + messageData
  }
}

class SignTransactionHandler: BaseHandler {
  override func canHandle(request: Request) -> Bool {
    return request.method == "eth_signTransaction"
  }
  
  override func handle(request: Request) {
    do {
      let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
      guard transaction.from == privateKey.address else {
        self.sever.send(.reject(request))
        return
      }
      askToSign(request: request, message: transaction.description) {
        let signedTx = try! transaction.sign(with: self.privateKey, chainId: EthereumQuantity(quantity: BigUInt(KNGeneralProvider.shared.customRPC.chainID)))
        let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
        return r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
      }
    } catch {
      self.sever.send(.invalid(request))
    }
  }
}

class SendTransactionHandler: BaseHandler {
  let chain = KNGeneralProvider.shared.currentChain
  
  override func canHandle(request: Request) -> Bool {
    return request.method == "eth_sendTransaction"
  }
  
  override func handle(request: Request) {
    do {
      let dict = try request.parameter(of: [String: String].self, at: 0)
      
      self.getLatestNonce { nonceInt in
        let gasPriceBigInt = KNGasCoordinator.shared.standardKNGas
        let value = BigInt(dict["value"]?.drop0x ?? "", radix: 16)?.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 4)
        let description = "\(value ?? "---") \(KNGeneralProvider.shared.quoteToken) to \(dict["to"] ?? "---")"
        self.askToAsyncSign(request: request, message: description) {
          guard let signTx = self.buildSignTransaction(dict: dict, nonce: nonceInt, gasPrice: gasPriceBigInt) else {
            return
          }
          let signResult = EthereumTransactionSigner().signTransaction(address: self.session.address, transaction: signTx)
          switch signResult {
          case .success(let signedData):
            KNGeneralProvider.shared.sendSignedTransactionData(signedData, completion: { sendResult in
              switch sendResult {
              case .success(let hash):
                print(hash)
                self.sever.send(.signature(hash, for: request))
              case .failure(let error):
                UIAlertController.showFailedError(from: self.controller, message: error.description)
              }
            })
          case .failure:
            UIAlertController.showFailedError(from: self.controller, message: "Fail")
          }
        }
      }
    } catch {
      self.sever.send(.invalid(request))
    }
  }
}

extension UIAlertController {
  func withCloseButton(title: String = "Close", onClose: (() -> Void)? = nil ) -> UIAlertController {
    addAction(UIAlertAction(title: title, style: .cancel) { _ in onClose?() } )
    return self
  }
  
  static func showShouldStart(from controller: UIViewController, clientName: String, onStart: @escaping () -> Void, onClose: @escaping (() -> Void)) {
    let alert = UIAlertController(title: "Request to start a session", message: clientName, preferredStyle: .alert)
    let startAction = UIAlertAction(title: "Start", style: .default) { _ in onStart() }
    alert.addAction(startAction)
    controller.present(alert.withCloseButton(onClose: onClose), animated: true)
  }
  
  static func showFailedToConnect(from controller: UIViewController) {
    let alert = UIAlertController(title: "Failed to connect", message: nil, preferredStyle: .alert)
    controller.present(alert.withCloseButton(), animated: true)
  }
  
  static func showFailedError(from controller: UIViewController, message: String) {
    let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
    controller.present(alert.withCloseButton(), animated: true)
  }
  
  static func showDisconnected(from controller: UIViewController) {
    let alert = UIAlertController(title: "Did disconnect", message: nil, preferredStyle: .alert)
    controller.present(alert.withCloseButton(), animated: true)
  }
  
  static func showShouldSign(from controller: UIViewController, title: String, message: String, onSign: @escaping () -> Void, onCancel: @escaping () -> Void) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let startAction = UIAlertAction(title: "Sign", style: .default) { _ in onSign() }
    alert.addAction(startAction)
    controller.present(alert.withCloseButton(title: "Reject", onClose: onCancel), animated: true)
  }
}

extension EthereumTransaction {
  var description: String {
    return """
        to: \(String(describing: to!.hex(eip55: true))),
        value: \(String(describing: value!.hex())),
        gasPrice: \(String(describing: gasPrice!.hex())),
        gas: \(String(describing: gas!.hex())),
        data: \(data.hex()),
        nonce: \(String(describing: nonce!.hex()))
        """
  }
}

extension KNWalletConnectViewController: ServerDelegate {
  func server(_ server: Server, didFailToConnect url: WCURL) {
    onMainThread {
      UIAlertController.showFailedToConnect(from: self)
    }
  }
  
  func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
    let walletMeta = Session.ClientMeta(name: "Test Wallet",
                                        description: nil,
                                        icons: [],
                                        url: URL(string: "https://safe.gnosis.io")!)
    let walletInfo = Session.WalletInfo(approved: true,
                                        accounts: [privateKey.address.hex(eip55: true)],
                                        chainId: KNGeneralProvider.shared.customRPC.chainID,
                                        peerId: UUID().uuidString,
                                        peerMeta: walletMeta)
    onMainThread {
      UIAlertController.showShouldStart(from: self, clientName: session.dAppInfo.peerMeta.name, onStart: {
        completion(walletInfo)
      }, onClose: {
        completion(Session.WalletInfo(approved: false, accounts: [], chainId: KNGeneralProvider.shared.customRPC.chainID, peerId: "", peerMeta: walletMeta))
      })
    }
  }
  
  func server(_ server: Server, didConnect session: Session) {
    self.session = session
    let sessionData = try! JSONEncoder().encode(session)
    UserDefaults.standard.set(sessionData, forKey: sessionKey)
    onMainThread {
      self.connectionStatusUpdated(true)
      self.updateWCInfo()
    }
  }
  
  func server(_ server: Server, didDisconnect session: Session) {
    UserDefaults.standard.removeObject(forKey: sessionKey)
    onMainThread {
      self.connectionStatusUpdated(false)
    }
  }
  
  func server(_ server: Server, didUpdate session: Session) {
    // no-op
  }
}

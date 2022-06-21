// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var qrcodeImageView: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var qrcodeImageContainer: UIView!
  @IBOutlet weak var copyWalletButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var infoLabel: UILabel!
  @IBOutlet weak var addressTypeLabel: UILabel!
  @IBOutlet weak var scanButton: UIButton!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  
  fileprivate var viewModel: KNWalletQRCodeViewModel

  fileprivate let style = KNAppStyleType.current

  init(viewModel: KNWalletQRCodeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNWalletQRCodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupWalletData()
    self.setupButtons()
  }


  fileprivate func setupWalletData() {
    self.titleLabel.text = Strings.receive
    self.addressLabel.text = viewModel.addressString
    self.qrcodeImageContainer.rounded(radius: 16)
    self.loadingIndicator.startAnimating()
    let addressString = self.viewModel.addressString
    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: addressString)
      DispatchQueue.main.async {
        self.qrcodeImageView.image = image
        self.loadingIndicator.stopAnimating()
        self.loadingIndicator.isHidden = true
      }
    }
  }

  fileprivate func setupButtons() {
    self.shareButton.rounded(
      radius: 16
    )
    self.copyWalletButton.rounded(
      color: UIColor.Kyber.SWButtonBlueColor,
      width: 1.0,
      radius: 16
    )
    self.copyWalletButton.setTitle(Strings.copy, for: .normal)
    self.shareButton.setTitle(Strings.share, for: .normal)
    let token = KNGeneralProvider.shared.tokenType
    let quoteToken = KNGeneralProvider.shared.quoteToken.uppercased()
    self.infoLabel.text = String(format: Strings.receiveWarningText, token, quoteToken)
    self.addressTypeLabel.text = String(format: Strings.tokenTypeAddress, token)
    self.scanButton.setTitle(String(format: Strings.viewOnX, KNGeneralProvider.shared.currentChain.customRPC().webScanName), for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyWalletButtonPressed(_ sender: Any) {
    UIPasteboard.general.string = self.viewModel.addressString

    self.showMessageWithInterval(message: Strings.addressCopied)
  }

  @IBAction func scanButtonTapped(_ sender: Any) {
    let urlString = "\(KNGeneralProvider.shared.customRPC.etherScanEndpoint)address/\(self.viewModel.addressString)"
    self.openSafari(with: urlString)
  }
  @IBAction func shareButtonPressed(_ sender: UIButton) {
    let activityItems: [Any] = {
      var items: [Any] = []
      items.append(self.viewModel.shareText)
      if let image = self.qrcodeImageView.image { items.append(image) }
      return items
    }()
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    activityViewController.popoverPresentationController?.sourceView = sender
    self.present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.navigationController?.popViewController(animated: true)
    }
  }
}

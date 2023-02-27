//
//  ConfirmSendNFTViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 27/08/2021.
//

import UIKit
import BigInt
import Utilities

class ConfirmSendNFTViewModel {
  let nftItem: NFTItem
  let nftCategory: NFTSection
  let gasPrice: BigInt
  let gasLimit: BigInt
  let ens: String?
  let address: String
  let amount: Int
  let supportERC721: Bool
  
  var advancedGasLimit: String?
  var advancedMaxPriorityFee: String?
  var advancedMaxFee: String?
  var advancedNonce: String?
  
  init(nftItem: NFTItem, nftCategory: NFTSection, gasPrice: BigInt, gasLimit: BigInt, address: String, ens: String?, amount: Int, supportERC721: Bool, advancedGasLimit: String?, advancedMaxPriorityFee: String?, advancedMaxFee: String?, advancedNonce: String?) {
    self.nftItem = nftItem
    self.nftCategory = nftCategory
    self.gasPrice = gasPrice
    self.gasLimit = gasLimit
    self.address = address
    self.ens = ens
    self.amount = amount
    self.supportERC721 = supportERC721
    self.advancedGasLimit = advancedGasLimit
    self.advancedMaxPriorityFee = advancedMaxPriorityFee
    self.advancedMaxFee = advancedMaxFee
    self.advancedNonce = advancedNonce
  }
  
  var addressToIcon: UIImage? {
    guard let data = self.address.dataFromHex() else { return nil }
    return UIImage.generateImage(with: 75, hash: data)
  }

  var titleString: String {
    return "Sending confirm".toBeLocalised().uppercased()
  }

  var contactName: String {
    guard let contact = KNContactStorage.shared.contacts.first(where: { address.lowercased() == $0.address.lowercased() }) else {
      let text = NSLocalizedString("not.in.contact", value: "Not In Contact", comment: "")
      if let ens = self.ens { return "\(ens) - \(text)" }
      return text
    }
    if let ens = self.ens { return "\(ens) - \(contact.name)" }
    return contact.name
  }
  
  var transactionGasPriceString: String {
    let gasPriceText = gasPrice.shortString(
      units: .gwei,
      maxFractionDigits: 5
    )
    let gasLimitText = EtherNumberFormatter.short.string(from: gasLimit, decimals: 0)
    let labelText = String(format: NSLocalizedString("%@ (Gas Price) * %@ (Gas Limit)", comment: ""), gasPriceText, gasLimitText)
    return labelText
  }
  
  var transactionFeeUSDString: String {
    let feeBigInt = gasPrice * gasLimit
    guard let price = KNTrackerRateStorage.shared.getETHPrice() else { return "" }
    let usd = feeBigInt * BigInt(price.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
    let valueString: String = usd.displayRate(decimals: 18)
    return "~ \(valueString) USD"
  }
  
  var transactionFeeETHString: String {
    let feeBigInt = gasPrice * gasLimit
    let feeString: String = feeBigInt.displayRate(decimals: 18)
    return "\(feeString) \(KNGeneralProvider.shared.quoteToken)"
  }
}

class ConfirmSendNFTViewController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!

  @IBOutlet weak var chainIcon: UIImageView!
  @IBOutlet weak var chainLabel: UILabel!
  
  @IBOutlet weak var contactImageView: UIImageView!
  @IBOutlet weak var contactNameLabel: UILabel!
  @IBOutlet weak var sendAddressLabel: UILabel!
  
  @IBOutlet weak var feeETHLabel: UILabel!
  @IBOutlet weak var feeUSDLabel: UILabel!

  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  
  @IBOutlet weak var transactionFeeTextLabel: UILabel!
  @IBOutlet weak var gasPriceTextLabel: UILabel!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var warningMessage: UILabel!
  @IBOutlet weak var nftImageView: UIImageView!
  @IBOutlet weak var nftNameLabel: UILabel!
  @IBOutlet weak var nftIDLabel: UILabel!
  @IBOutlet weak var amountTitleLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var nftContainerView: UIView!
  
  weak var delegate: KConfirmSendViewControllerDelegate?
  fileprivate let viewModel: ConfirmSendNFTViewModel
  let transitor = TransitionDelegate()

  init(viewModel: ConfirmSendNFTViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ConfirmSendNFTViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setupUI()
    self.setupChainInfo()
    
    //trick fix
    KNGeneralProvider.shared.getDecimalsEncodeData { result in
    }
  }
  
  func setupChainInfo() {
    chainIcon.image = KNGeneralProvider.shared.currentChain.squareIcon()
    chainLabel.text = KNGeneralProvider.shared.currentChain.chainName()
  }

  fileprivate func setupUI() {
    self.contactImageView.rounded(radius: self.contactImageView.frame.height / 2.0)
    self.contactImageView.image = self.viewModel.addressToIcon

    self.contactNameLabel.text = self.viewModel.contactName
    self.sendAddressLabel.text = self.viewModel.address
    
    self.feeETHLabel.text = self.viewModel.transactionFeeETHString
    self.feeUSDLabel.text = self.viewModel.transactionFeeUSDString
    gasPriceTextLabel.text = viewModel.transactionGasPriceString
    self.confirmButton.rounded(radius: 16)
    self.cancelButton.rounded(radius: 16)

    let chain = KNGeneralProvider.shared.chainName
    self.warningMessage.text = "Please sure that this address supports \(chain) network. You will lose your assets if this address doesn't support \(chain) compatible retrieval"
    self.updateUINFTItem()
    self.amountTitleLabel.isHidden = self.viewModel.supportERC721
    self.amountLabel.isHidden = self.viewModel.supportERC721
    self.amountLabel.text = self.viewModel.supportERC721 ? "" : "\(self.viewModel.amount)"
    
    self.nftContainerView.dropShadow(color: UIColor.black, offSet: CGSize(width: -1, height: 1), radius: 16)
  }
  
  func updateUINFTItem() {
    self.nftImageView.setImage(with: self.viewModel.nftItem.externalData.image, placeholder: UIImage(named: "placeholder_nft_item")!, size: nil, applyNoir: false)
    self.nftNameLabel.text = self.viewModel.nftItem.externalData.name
    self.nftIDLabel.text = "#" + self.viewModel.nftItem.tokenID
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func confirmButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      let historyTransaction = InternalHistoryTransaction(
        type: .transferToken,
        state: .pending,
        fromSymbol: "NFT",
        toSymbol: nil,
        transactionDescription: "Tranfering \(self.viewModel.nftItem.externalData.name)",
        transactionDetailDescription: "",
        transactionObj: SignTransactionObject(
          value: "",
          from: "",
          to: "",
          nonce: 0,
          data: Data(),
          gasPrice: "",
          gasLimit: "",
          chainID: 0,
          reservedGasLimit: ""
        ),
        eip1559Tx: nil
      )
        let extra = [
            "nftInfo": self.viewModel.nftItem.externalData.externalDataDescription,
            "nftType": self.viewModel.nftCategory.collectibleName,
            "collectibleAddress": self.viewModel.nftCategory.collectibleAddress
        ]
        historyTransaction.trackingExtraData = extra
      historyTransaction.transactionSuccessDescription = "Tranfer successfull \(self.viewModel.nftItem.externalData.name)"

      self.delegate?.kConfirmSendViewController(self, run: .confirmNFT(
        nftItem: self.viewModel.nftItem,
        nftCategory: self.viewModel.nftCategory,
        gasPrice: self.viewModel.gasPrice,
        gasLimit: self.viewModel.gasLimit,
        address: self.viewModel.address,
        amount: self.viewModel.amount,
        isSupportERC721: self.viewModel.supportERC721,
        historyTransaction: historyTransaction,
        advancedGasLimit: self.viewModel.advancedGasLimit,
        advancedPriorityFee: self.viewModel.advancedMaxPriorityFee,
        advancedMaxFee: self.viewModel.advancedMaxFee,
        advancedNonce: self.viewModel.advancedNonce
      ))
    })
  }
  
  @IBAction func helpGasFeeButtonTapped(_ sender: UIButton) {
    self.showBottomBannerView(
      message: "The.actual.cost.of.the.transaction.is.generally.lower".toBeLocalised(),
      icon: UIImage(named: "help_icon_large") ?? UIImage(),
      time: 3
    )
  }
}

extension ConfirmSendNFTViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 650
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

//
//  SwitchChainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 5/21/21.
//

import UIKit

class SwitchChainViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  
  @IBOutlet weak var ethCheckMarkIcon: UIImageView!
  @IBOutlet weak var bscCheckMarkIcon: UIImageView!
  @IBOutlet weak var maticCheckMarkIcon: UIImageView!
  @IBOutlet weak var avalancheCheckMarkIcon: UIImageView!
  @IBOutlet weak var cronosCheckMarkIcon: UIImageView!
  @IBOutlet weak var fantomCheckMarkIcon: UIImageView!
  
  @IBOutlet weak var ethSelectBgView: UIView!
  @IBOutlet weak var bscSelectBgView: UIView!
  @IBOutlet weak var maticSelectBgView: UIView!
  @IBOutlet weak var avalancheSelectBgView: UIView!
  @IBOutlet weak var cronosSelectBgView: UIView!
  @IBOutlet weak var fantomSelectBgView: UIView!

  var nextButtonTitle: String = "Next"
  var selectedChain: ChainType
  var completionHandler: (ChainType) -> Void = { selected in }
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  init() {
    self.selectedChain = KNGeneralProvider.shared.currentChain
    super.init(nibName: SwitchChainViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
    
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.updateSelectedChainUI()
    self.cancelButton.rounded(radius: 16)
    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(self.nextButtonTitle, for: .normal)
  }
  
  fileprivate func updateSelectedChainUI() {
    self.ethCheckMarkIcon.isHidden = !(self.selectedChain == .eth)
    self.bscCheckMarkIcon.isHidden = !(self.selectedChain == .bsc)
    self.maticCheckMarkIcon.isHidden = !(self.selectedChain == .polygon)
    self.avalancheCheckMarkIcon.isHidden = !(self.selectedChain == .avalanche)
    self.cronosCheckMarkIcon.isHidden = !(self.selectedChain == .cronos)
    self.fantomCheckMarkIcon.isHidden = !(self.selectedChain == .fantom)
    
    self.ethSelectBgView.isHidden = !(self.selectedChain == .eth)
    self.bscSelectBgView.isHidden = !(self.selectedChain == .bsc)
    self.maticSelectBgView.isHidden = !(self.selectedChain == .polygon)
    self.avalancheSelectBgView.isHidden = !(self.selectedChain == .avalanche)
    self.cronosSelectBgView.isHidden = !(self.selectedChain == .cronos)
    self.fantomSelectBgView.isHidden = !(self.selectedChain == .fantom)

    let enableNextButton = self.selectedChain != KNGeneralProvider.shared.currentChain
    self.nextButton.isEnabled = enableNextButton
    self.nextButton.alpha = enableNextButton ? 1.0 : 0.5
  }

  @IBAction func ethButtonTapped(_ sender: UIButton) {
    self.selectedChain = .eth
    self.updateSelectedChainUI()
  }
  
  @IBAction func bscButtonTapped(_ sender: UIButton) {
    self.selectedChain = .bsc
    self.updateSelectedChainUI()
  }

  @IBAction func polygonButtonTapped(_ sender: UIButton) {
    self.selectedChain = .polygon
    self.updateSelectedChainUI()
  }
  
  @IBAction func avalancheButtonTapped(_ sender: UIButton) {
    self.selectedChain = .avalanche
    self.updateSelectedChainUI()
  }

  @IBAction func cronosButtonTapped(_ sender: Any) {
    self.selectedChain = .cronos
    self.updateSelectedChainUI()
  }
  
  @IBAction func fantomButtonTapped(_ sender: Any) {
    self.selectedChain = .fantom
    self.updateSelectedChainUI()
  }

  @IBAction func nextButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      self.completionHandler(self.selectedChain)
    })
  }
  
  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SwitchChainViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 550
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

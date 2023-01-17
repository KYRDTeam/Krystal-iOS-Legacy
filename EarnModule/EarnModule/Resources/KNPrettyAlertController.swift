// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BaseModule
import Utilities
import DesignSystem

class KNPrettyAlertController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var secondButton: UIButton!
  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  
  @IBOutlet weak var popupHeightContraint: NSLayoutConstraint!
  @IBOutlet var backgroundView: UIView!

  let mainTitle: String?
  let isWarning: Bool
  let message: String
  let secondButtonTitle: String?
  let firstButtonTitle: String
  let secondButtonAction:  (() -> Void)?
  let firstButtonAction: (() -> Void)?
  var gradientButton: UIButton!
  let transitor = TransitionDelegate()
  var popupHeight: CGFloat = 300
    var tapRange: NSRange?
    var swapLinkTap: (() -> Void)?
    var transitionText: String = ""
  init(title: String?,
       isWarning: Bool = false,
       message: String,
       secondButtonTitle: String?,
       firstButtonTitle: String = "cancel".toBeLocalised(),
       secondButtonAction: (() -> Void)?,
       firstButtonAction: (() -> Void)?) {
    self.mainTitle = title
    self.isWarning = isWarning
    self.message = message
    self.secondButtonTitle = secondButtonTitle
    self.firstButtonTitle = firstButtonTitle
    self.secondButtonAction = secondButtonAction
    self.firstButtonAction = firstButtonAction
    super.init(nibName: KNPrettyAlertController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configUI()
  }
  
  func configUI() {
    self.containerView.rounded()
    self.secondButton.rounded(radius: 16)
    self.firstButton.rounded(radius: 16)
    if let titleTxt = self.mainTitle {
      if self.isWarning {
        let fullString = NSMutableAttributedString()
        let image1Attachment = NSTextAttachment()
        let iconImage = Images.warningYellowIcon
        let titleFont = UIFont.karlaBold(ofSize: 20)
        image1Attachment.bounds = CGRect(x: 0, y: (titleFont.capHeight - iconImage.size.height).rounded() / 2, width: iconImage.size.width, height: iconImage.size.height)
        image1Attachment.image = iconImage
        let image1String = NSAttributedString(attachment: image1Attachment)
        fullString.append(image1String)
        fullString.append(NSAttributedString(string: " " + titleTxt))
        self.titleLabel.attributedText = fullString
      } else {
        self.titleLabel.text = titleTxt
      }
      
    } else {
      self.titleLabel.removeFromSuperview()
      let messageTopContraint = NSLayoutConstraint(item: self.contentLabel, attribute: .top, relatedBy: .equal, toItem: self.containerView, attribute: .top, multiplier: 1, constant: 33)
      self.containerView.addConstraint(messageTopContraint)
    }
      if !transitionText.isEmpty, message.suffix(transitionText.count) == transitionText {
          let linkAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.karlaBold(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor(named: "buttonBackgroundColor")!,
          ]
          let textAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.font: UIFont.karlaMedium(ofSize: 16),
            NSAttributedString.Key.foregroundColor: UIColor(named: "textWhiteColor")!,
          ]
          let attributionString = NSMutableAttributedString(string: message, attributes: textAttributes)
          let highlightRange = NSString(string: message).range(of: transitionText)
          attributionString.setAttributes(linkAttributes, range: highlightRange)
          contentLabel.attributedText = attributionString
          contentLabel.isUserInteractionEnabled = true
          let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSwapText(_:)))
          contentLabel.addGestureRecognizer(tapGesture)
          tapRange = highlightRange
      } else {
          self.contentLabel.text = message
      }
    
    self.firstButton.setTitle(firstButtonTitle, for: .normal)
    if let yesTxt = self.secondButtonTitle {
      self.secondButton.setTitle(yesTxt, for: .normal)
      self.gradientButton = self.secondButton
    } else {
      self.secondButton.removeFromSuperview()
      let noButtonTrailingContraint = NSLayoutConstraint(item: self.firstButton, attribute: .trailing, relatedBy: .equal, toItem: self.containerView, attribute: .trailing, multiplier: 1, constant: -36)
      self.containerView.addConstraint(noButtonTrailingContraint)
      self.firstButton.rounded()
      self.firstButton.backgroundColor = AppTheme.current.orangeColor
      self.firstButton.setTitleColor(.white, for: .normal)
      self.gradientButton = firstButton
    }
    self.gradientButton.backgroundColor = UIColor(named: "buttonBackgroundColor")
    self.gradientButton.setTitleColor(UIColor(named: "mainViewBgColor"), for: .normal)
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    backgroundView.addGestureRecognizer(tapGesture)
    self.popupHeightContraint.constant = self.popupHeight
  }
  
  @objc func tapOutside() {
    guard !self.isWarning else { return }
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func yesButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: self.secondButtonAction)
  }

  @IBAction func noButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: self.firstButtonAction)
  }
    
    @objc func tapSwapText(_ sender: UITapGestureRecognizer) {
        guard let tapRange = tapRange else {
            return
        }

        if sender.didTapAttributedTextInLabel(label: contentLabel, inRange: tapRange) {
            self.dismiss(animated: true) {
                self.swapLinkTap?()
            }
        }
    }
}

extension KNPrettyAlertController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.popupHeight
  }

  func getPopupContentView() -> UIView {
    return self.containerView
  }
}

extension UITapGestureRecognizer {
    
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        
        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y);
        var indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
//        indexOfCharacter = indexOfCharacter + 4
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
    
}

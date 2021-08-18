// Copyright SIX DAY LLC. All rights reserved.

import UIKit

struct KMinAcceptableRatePopupViewModel {
  let minRate: String
  let symbol: String

  var titleAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedString.Key.font: UIFont.Kyber.medium(with: 16),
      NSAttributedString.Key.kern: 0.0,
    ]
  }

  var descAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedString.Key.font: UIFont.Kyber.medium(with: 14),
      NSAttributedString.Key.kern: 0.0,
    ]
  }

  var highlightedAttributes: [NSAttributedString.Key: Any] {
    return [
      NSAttributedString.Key.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedString.Key.font: UIFont.Kyber.bold(with: 14),
      NSAttributedString.Key.kern: 0.0,
    ]
  }

  init(minRate: String, symbol: String) {
    self.minRate = minRate
    self.symbol = symbol
  }

  var attributedString: NSAttributedString {
    let attributedString = NSMutableAttributedString()
    let localisedMinAcceptablRate = NSLocalizedString("min.acceptable.rate", value: "Min Acceptable Rate", comment: "")
    attributedString.append(NSAttributedString(string: localisedMinAcceptablRate, attributes: self.titleAttributes))
    let localisedVolatileTime = NSLocalizedString(
      "guard.yourself.during.volatile.times.by.settings.lowest.conversion.rate",
      value: "Guard yourself during volatile times by setting the lowest conversion rate you would accept for this transaction.",
      comment: ""
    )
    attributedString.append(NSAttributedString(string: "\n\n\(localisedVolatileTime)\n", attributes: self.descAttributes))
    let localisedSettingsHighValue = NSLocalizedString(
      "setting.a.high.value.may.result.in.a.failed.transaction",
      value: "Setting a high value may result in a failed transaction and you would be charged gas fees.",
      comment: ""
    )
    attributedString.append(NSAttributedString(string: "\(localisedSettingsHighValue)\n\n", attributes: self.descAttributes))
    let localisedRecommendRate = NSLocalizedString("our.recommended.min.acceptable.rate", value: "Our recommended Min Acceptable Rate is", comment: "")
    attributedString.append(NSAttributedString(string: "\(localisedRecommendRate) ", attributes: self.descAttributes))
    attributedString.append(NSAttributedString(string: minRate, attributes: self.highlightedAttributes))
    attributedString.append(NSAttributedString(string: " \(symbol)", attributes: self.descAttributes))
    return attributedString
  }
}

class KMinAcceptableRatePopupViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var desciptionLabel: UILabel!
  let viewModel: KMinAcceptableRatePopupViewModel

  init(viewModel: KMinAcceptableRatePopupViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KMinAcceptableRatePopupViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.desciptionLabel.attributedText = self.viewModel.attributedString
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    if sender.location(in: self.view).y <= self.containerView.frame.minY {
      self.dismiss(animated: true, completion: nil)
    }
  }
}

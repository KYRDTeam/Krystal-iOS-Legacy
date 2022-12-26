// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Lottie
class KNWelcomeScreenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWelcomeScreenCollectionViewCellID"
  static let height: CGFloat = 292

  @IBOutlet weak var animationView: LottieAnimationView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
  }

  func updateCell(with data: KNWelcomeScreenViewModel.KNWelcomeData) {
    self.animationView.animation = LottieAnimation.named(data.jsonFileName)
    self.animationView.contentMode = .scaleAspectFit
    self.animationView.loopMode = .loop
  }
  
  func playAnimation() {
    self.animationView.play()
  }
}

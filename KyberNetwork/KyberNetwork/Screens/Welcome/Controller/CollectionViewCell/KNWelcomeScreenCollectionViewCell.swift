// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Lottie
class KNWelcomeScreenCollectionViewCell: UICollectionViewCell {

  static let cellID: String = "kWelcomeScreenCollectionViewCellID"
  static let height: CGFloat = 292

  @IBOutlet weak var animationView: AnimationView!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
  }

  func updateCell(with data: KNWelcomeScreenViewModel.KNWelcomeData) {
    self.animationView.animation = Animation.named(data.jsonFileName)
    self.animationView.contentMode = .scaleAspectFit
    self.animationView.loopMode = .loop
    self.animationView.animationSpeed = 0.35
    self.animationView.play()
   
  }
}

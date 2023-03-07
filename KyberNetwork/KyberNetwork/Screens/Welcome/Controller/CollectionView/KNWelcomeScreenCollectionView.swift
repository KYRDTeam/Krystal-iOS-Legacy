// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import DesignSystem

class KNWelcomeScreenCollectionView: XibLoaderView {

  static let height: CGFloat = KNWelcomeScreenCollectionViewCell.height + 20.0
  @IBOutlet weak var collectionView: UICollectionView!
  fileprivate let viewModel: KNWelcomeScreenViewModel = KNWelcomeScreenViewModel()
  @IBOutlet var pageViews: [UIView]!
  @IBOutlet weak var landingTitle: UILabel!
  @IBOutlet weak var landingDescription: UILabel!
  static let paggerWidth = CGFloat(52)
  fileprivate var didShowFirstCell = false
  fileprivate var currentIndex: Int = 0
    
  override func commonInit() {
    super.commonInit()
    self.backgroundColor = .clear
    let nib = UINib(nibName: KNWelcomeScreenCollectionViewCell.className, bundle: nil)
    self.collectionView.register(
      nib,
      forCellWithReuseIdentifier: KNWelcomeScreenCollectionViewCell.cellID
    )
    self.collectionView.delegate = self
    self.collectionView.dataSource = self
    self.pageViews.forEach { $0.rounded(radius: 1.0) }
    self.updateSelectedPageView()
    self.collectionView.reloadData()
  }

  fileprivate func updateSelectedPageView() {
      let normalWidth = 80.0
      self.pageViews.forEach { view in
          if view.tag != self.currentIndex {
              view.layer.removeAllAnimations()
          }
          
          view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: normalWidth, height: 2)
          view.backgroundColor = .clear
      }

    self.pageViews.forEach { view in
        view.backgroundColor = view.tag < self.currentIndex ? AppTheme.current.lineColor : .clear
        
        if view.tag == self.currentIndex {
            view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: 0, height: 2)
            view.backgroundColor = AppTheme.current.lineColor
            UIView.animate(withDuration: 3) {
                view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: normalWidth, height: 2)
            } completion: { complete in
                if complete {
                    self.forward()
                }
            }

        }
    }
  }
    
    func forward() {
        guard currentIndex < 3 else { return }
        let cellSize = CGSize(width: self.collectionView.frame.width, height: KNWelcomeScreenCollectionViewCell.height)
        let contentOffset = self.collectionView.contentOffset
        self.collectionView.scrollRectToVisible(CGRect(x: contentOffset.x + cellSize.width, y: contentOffset.y, width: cellSize.width, height: cellSize.height), animated: true)
        self.currentIndex += 1
        self.updateSelectedPageView()
        self.updateUIFor(index: currentIndex)
    }

    func backward() {
        guard self.currentIndex > 0 else { return }
        let cellSize = CGSize(width: self.collectionView.frame.width, height: KNWelcomeScreenCollectionViewCell.height)
        let contentOffset = self.collectionView.contentOffset
        self.collectionView.scrollRectToVisible(CGRect(x: contentOffset.x - cellSize.width, y: contentOffset.y, width: cellSize.width, height: cellSize.height), animated: true)
        self.currentIndex -= 1
        self.updateSelectedPageView()
        self.updateUIFor(index: currentIndex)
    }

    fileprivate func updateUIFor(index: Int) {
        let data = self.viewModel.welcomeData(at: index)
        self.landingTitle.text = data.title
        self.landingDescription.text = data.subtitle
    }

    func pause() {
        self.pageViews.forEach { view in
            if view.tag == self.currentIndex {
                self.pauseLayer(layer: view.layer)
            }
        }
    }
    
    func resume() {
        self.pageViews.forEach { view in
            if view.tag == self.currentIndex {
                self.resumeLayer(layer: view.layer)
            }
        }
    }
    
    func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}

extension KNWelcomeScreenCollectionView: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return .zero
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width,
      height: KNWelcomeScreenCollectionViewCell.height
    )
  }
}

extension KNWelcomeScreenCollectionView: UIScrollViewDelegate {
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let offsetX = scrollView.contentOffset.x
    let currentPage = Int(round(offsetX / scrollView.frame.width))
    self.currentIndex = currentPage
    self.updateSelectedPageView()
    self.updateUIFor(index: currentPage)
  }
}

extension KNWelcomeScreenCollectionView: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.viewModel.numberRows
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: KNWelcomeScreenCollectionViewCell.cellID,
      for: indexPath
    ) as! KNWelcomeScreenCollectionViewCell
    let data = self.viewModel.welcomeData(at: indexPath.row)
    cell.updateCell(with: data)
    if !didShowFirstCell && indexPath.row == 0 {
      cell.playAnimation()
      didShowFirstCell = true
    }
    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    for indexPath in self.collectionView.indexPathsForVisibleItems {
      let cell = self.collectionView.cellForItem(at: indexPath) as! KNWelcomeScreenCollectionViewCell
      cell.playAnimation()
      Tracker.track(event: .introSwipeOnboard)
    }
  }
}

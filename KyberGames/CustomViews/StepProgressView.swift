//
//  StepProgressView.swift
//  KyberGames
//
//  Created by Nguyen Tung on 05/04/2022.
//

import UIKit

protocol StepProgressViewDelegate: AnyObject {
  func stepProgressView(_ stepProgressView: StepProgressView, sizeForItemAt index: Int) -> CGSize
  func stepProgressView(_ stepProgressView: StepProgressView, frameForConnectionLineAfter index: Int) -> CGRect
  func stepProgressView(_ stepProgressView: StepProgressView, colorForConnectionLineAfter index: Int) -> UIColor
  func insets(_ stepProgressView: StepProgressView) -> UIEdgeInsets
  func itemSpacing(_ stepProgressView: StepProgressView) -> CGFloat
}

protocol StepProgressViewDataSource: AnyObject {
  func numberOfItems(_ stepProgressView: StepProgressView) -> Int
  func stepProgressView(_ stepProgressView: StepProgressView, cellForItemAt index: Int) -> UICollectionViewCell
}

extension StepProgressViewDelegate {
  func insets(_ stepProgressView: StepProgressView) -> UIEdgeInsets {
    return .zero
  }
  func itemSpacing(_ stepProgressView: StepProgressView) -> CGFloat {
    return .zero
  }
}

class StepProgressView: UIView {
  
  weak var contentView: UIView!
  weak var collectionViewLayout: UICollectionViewFlowLayout!
  weak var collectionView: UICollectionView!
  
  weak var delegate: StepProgressViewDelegate?
  weak var dataSource: StepProgressViewDataSource?
  
  var direction: UICollectionView.ScrollDirection = .horizontal {
    didSet {
      collectionViewLayout.scrollDirection = direction
    }
  }
  
  var connectionLines: [CAShapeLayer] = []
  
  override init(frame: CGRect) {
      super.init(frame: frame)
      self.commonInit()
  }
  
  required init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
      self.commonInit()
  }
  
  fileprivate func commonInit() {
    let contentView = UIView(frame: CGRect.zero)
    contentView.backgroundColor = UIColor.clear
    self.addSubview(contentView)
    self.contentView = contentView
    
    let collectionViewLayout = UICollectionViewFlowLayout()
    collectionViewLayout.scrollDirection = .horizontal
    let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = UIColor.clear
    self.contentView.addSubview(collectionView)
    self.collectionView = collectionView
    self.collectionViewLayout = collectionViewLayout
  }
  
  override func layoutSubviews() {
      super.layoutSubviews()

      self.contentView.frame = self.bounds
      self.collectionView.frame = self.contentView.bounds
      self.reloadConnections()
  }
  
  func reloadConnections() {
    connectionLines.forEach { layer in layer.removeFromSuperlayer() }
    connectionLines = []
    let itemsCount = dataSource!.numberOfItems(self)
    for index in 0..<itemsCount - 1 {
      let shapeLayer = connectionLineLayer(after: index)
      collectionView.layer.insertSublayer(shapeLayer, at: 0)
      connectionLines.append(shapeLayer)
    }
  }
  
  func connectionLineLayer(after index: Int) -> CAShapeLayer {
    let frame = delegate!.stepProgressView(self, frameForConnectionLineAfter: index)
    let color = delegate!.stepProgressView(self, colorForConnectionLineAfter: index)
    let layer = CAShapeLayer()
    layer.path = UIBezierPath(rect: frame).cgPath
    layer.fillColor = color.cgColor
    return layer
  }
  
  func center(ofItemAt index: Int) -> CGPoint {
    return collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.center ?? .zero
  }
  
  func frame(ofItemAt index: Int) -> CGRect {
    return collectionView.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame ?? .zero
  }
  
  func reload() {
    collectionView.reloadData()
    reloadConnections()
  }
  
}

extension StepProgressView: UICollectionViewDelegate, UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataSource!.numberOfItems(self)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return dataSource!.stepProgressView(self, cellForItemAt: indexPath.item)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return delegate!.insets(self)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return delegate!.itemSpacing(self)
  }
  
}

extension StepProgressView: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return delegate!.stepProgressView(self, sizeForItemAt: indexPath.item)
  }
  
}

extension StepProgressView {
  
  func dequeueReusableCell<T: UICollectionViewCell>(_ aClass: T.Type, for index: Int) -> T! {
    let name = String(describing: aClass)
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: IndexPath(item: index, section: 0)) as? T else  {
      fatalError("\(name) is not registed")
    }
    return cell
  }
  
  func registerCellNib<T: UICollectionViewCell>(_ aClass: T.Type) {
      let name = String(describing: aClass)
      let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
      collectionView.register(nib, forCellWithReuseIdentifier: name)
  }
  
}

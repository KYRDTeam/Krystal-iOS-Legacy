//
//  CustomSegmentView.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 18/07/2022.
//

import UIKit

class CustomSegmentView: BaseXibView {
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
  @IBOutlet weak var indicatorView: UIView!
  @IBOutlet weak var segmentContainer: UIView!
  @IBOutlet weak var segmentContainerWidth: NSLayoutConstraint!
  
  let itemWidth: CGFloat = 72
  var labels: [UILabel] = []
  var onSelectItem: ((Int) -> ())?
  
  var items: [String] = ["QR"] {
    didSet {
      self.selectedIndex = 0
      self.setupLabels()
    }
  }
  
  var selectedIndex: Int = 0 {
    didSet {
      UIView.animate(withDuration: 0.3) {
        self.indicatorView.frame = self.labels[self.selectedIndex].frame
      }
    }
  }

  override func commonInit() {
    super.commonInit()
    
    setupLabels()
  }
  
  func setupLabels() {
    labels.forEach { label in
      label.removeFromSuperview()
    }
    
    labels.removeAll(keepingCapacity: true)
    
    let spacing = CGFloat(4 * (items.count - 1)) + 8
    stackViewWidth.constant = itemWidth * CGFloat(items.count) + spacing
    segmentContainerWidth.constant = itemWidth * CGFloat(items.count) + spacing
    
    items.enumerated().forEach { (index, item) in
      let label = UILabel()
      label.text = item
      label.textColor = .white
      label.font = UIFont.systemFont(ofSize: 16)
      label.layer.cornerRadius = 19
      label.layer.masksToBounds = true
      label.textAlignment = .center
      label.frame = .init(x: 4 + index * 72 + 4 * index, y: 5, width: 72, height: 38)
      stackView.addSubview(label)
      
      let tapGesture = SegmentLabelTapGesture(target: self, action: #selector(onTapItem))
      tapGesture.index = index
      label.isUserInteractionEnabled = true
      label.addGestureRecognizer(tapGesture)
      
      labels.append(label)
    }
    
    indicatorView.frame = labels[selectedIndex].frame
  }
  
  @objc func onTapItem(_ gesture: UIGestureRecognizer) {
    guard let gesture = gesture as? SegmentLabelTapGesture else {
      return
    }
    guard selectedIndex != gesture.index else {
      return
    }
    self.selectedIndex = gesture.index
    self.onSelectItem?(selectedIndex)
  }
  
}

class SegmentLabelTapGesture: UITapGestureRecognizer {
  var index: Int = 0
}

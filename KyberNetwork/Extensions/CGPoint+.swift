//
//  CGPoint+.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 18/07/2022.
//

import UIKit

extension CGPoint {
  
  func distanceSquared(from: CGPoint) -> CGFloat {
      return (from.x - x) * (from.x - x) + (from.y - y) * (from.y - y)
  }

  func distance(from: CGPoint) -> CGFloat {
      return sqrt(distanceSquared(from: from))
  }
  
}

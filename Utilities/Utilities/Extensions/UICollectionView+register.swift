//
//  UICollectionView+register.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 30/03/2022.
//

import UIKit

public extension UICollectionView {
  
  func registerCell<T: UICollectionViewCell>(_ aClass: T.Type) {
    let name = String(describing: aClass)
    self.register(aClass, forCellWithReuseIdentifier: name)
  }
  
  func registerCellNib<T: UICollectionViewCell>(_ aClass: T.Type) {
      let name = String(describing: aClass)
      let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
      self.register(nib, forCellWithReuseIdentifier: name)
  }
  
  func dequeueReusableCell<T: UICollectionViewCell>(_ aClass: T.Type, indexPath: IndexPath) -> T! {
    let name = String(describing: aClass)
    guard let cell = self.dequeueReusableCell(withReuseIdentifier: name, for: indexPath) as? T else {
      fatalError("\(name) is not registed")
    }
    return cell
  }
  
  func registerHeaderCellNib<T: UICollectionReusableView>(_ aClass: T.Type) {
    let name = String(describing: aClass)
    let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
    self.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                  withReuseIdentifier: name)
  }
  
  func dequeueReusableHeaderCell<T: UICollectionReusableView>(_ aClass: T.Type, indexPath: IndexPath) -> T! {
    let name = String(describing: aClass)
    guard let cell = self.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: name, for: indexPath) as? T else  {
      fatalError("\(name) is not registed")
    }
    return cell
  }
  
  func registerFooterCellNib<T: UICollectionReusableView>(_ aClass: T.Type) {
    let name = String(describing: aClass)
    let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
    self.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: name)
  }
  
  func dequeueReusableFooterCell<T: UICollectionReusableView>(_ aClass: T.Type, indexPath: IndexPath) -> T! {
    let name = String(describing: aClass)
    
    guard let cell = self.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: name, for: indexPath) as? T else  {
      fatalError("\(name) is not registed")
    }
    return cell
  }
  
}

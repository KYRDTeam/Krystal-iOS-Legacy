//
//  ExploreBannersCell.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit
import FSPagerView

class ExploreBannersCell: UICollectionViewCell {
  @IBOutlet weak var pageView: FSPagerView!
  @IBOutlet weak var pageControl: FSPageControl!
  
  var onSelectBanner: ((Asset) -> ())?
  
  var banners: [Asset] = [] {
    didSet {
      self.pageControl.numberOfPages = banners.count
      self.pageView.reloadData()
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    pageControl.setFillColor(UIColor(named: "normalTextColor"), for: .normal)
    pageControl.setFillColor(UIColor(named: "buttonBackgroundColor"), for: .selected)
    pageView.register(FSPagerViewCell.self,
                      forCellWithReuseIdentifier: String(describing: FSPagerViewCell.self))
    pageView.dataSource = self
    pageView.delegate = self
  }
  
  func configure(banners: [Asset]) {
    self.banners = banners
  }
  
}

extension ExploreBannersCell: FSPagerViewDelegate, FSPagerViewDataSource {
  
  func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
    pagerView.deselectItem(at: index, animated: true)
    pagerView.scrollToItem(at: index, animated: true)
    onSelectBanner?(banners[index])
  }
  
  func numberOfItems(in pagerView: FSPagerView) -> Int {
    return banners.count
  }

  func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: String(describing: FSPagerViewCell.self), at: index)
    let url = URL(string: banners[index].imageURL)
    cell.imageView?.kf.setImage(with: url)
    cell.imageView?.contentMode = .scaleAspectFit
    cell.imageView?.clipsToBounds = true
    return cell
  }
  
  func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
    pageControl.currentPage = targetIndex
  }

  func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
    pageControl.currentPage = pagerView.currentIndex
  }
  
}

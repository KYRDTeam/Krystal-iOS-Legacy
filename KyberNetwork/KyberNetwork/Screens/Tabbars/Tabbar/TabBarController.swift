//
//  TabBarController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 09/12/2022.
//

import Foundation
import UIKit

class KNTabBarController: UITabBarController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        tabBar.tintColor = UIColor(named: "buttonBackgroundColor")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITabBar.appearance().unselectedItemTintColor = .white
    }
    
    func setupTabbarConstraints() {
        for vc in self.viewControllers ?? [] {
            vc.tabBarItem.title = nil
            vc.tabBarItem.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        }
    }
    
    func addNewTag(toItemAt index: Int) {
        let centerX = getCenterXOfItem(atIndex: index)
        
        let badgeView = UIView()
        badgeView.layer.cornerRadius = 4
        badgeView.layer.masksToBounds = true
        badgeView.backgroundColor = .red
        badgeView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.font = .karlaBold(ofSize: 8)
        label.text = "N"
        label.minimumScaleFactor = 0.5
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let width = "N".width(withConstrainedHeight: 16, font: .karlaBold(ofSize: 8))
        let height = "N".height(withConstrainedWidth: width, font: .karlaBold(ofSize: 8))
        
        badgeView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4),
            label.topAnchor.constraint(equalTo: badgeView.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: -2),
        ])
        
        tabBar.superview?.addSubview(badgeView)
        tabBar.superview?.bringSubviewToFront(badgeView)
        
        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: 6),
            badgeView.widthAnchor.constraint(equalToConstant: width + 8),
            badgeView.heightAnchor.constraint(equalToConstant: height + 4),
            badgeView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor, constant: centerX + 16 - (width + 8) / 2)
        ])
        
        view.layoutIfNeeded()
    }
    
    private func getCenterXOfItem(atIndex index: Int) -> CGFloat {
        let itemCount = tabBar.items?.count ?? 0
        
        return itemCount == 0 ? 0 : tabBar.frame.width / CGFloat(itemCount * 2) * CGFloat(index * 2 + 1)
    }
}

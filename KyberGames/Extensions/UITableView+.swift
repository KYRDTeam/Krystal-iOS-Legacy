//
//  UITableView+.swift
//  KyberGames
//
//  Created by Nguyen Tung on 07/04/2022.
//

import UIKit

extension UITableView {
    
    func registerCell<T: UITableViewCell>(_ aClass: T.Type) {
        let name = String(describing: aClass)
        self.register(aClass, forCellReuseIdentifier: name)
    }
    
    func registerCellNib<T: UITableViewCell>(_ aClass: T.Type) {
        let name = String(describing: aClass)
        let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
        self.register(nib, forCellReuseIdentifier: name)
    }

    func dequeueReusableCell<T: UITableViewCell>(_ aClass: T.Type, indexPath: IndexPath) -> T! {
        let name = String(describing: aClass)
        guard let cell = dequeueReusableCell(withIdentifier: name, for: indexPath) as? T else {
            fatalError("\(name) is not registed")
        }
        return cell
    }

    func registerHeaderFooterCellNib<T: UITableViewHeaderFooterView>(_ aClass: T.Type) {
        let name = String(describing: aClass)
        let nib = UINib(nibName: name, bundle: Bundle(for: T.self))
        self.register(nib, forHeaderFooterViewReuseIdentifier: name)
    }

    func dequeueReusableHeaderFooterCell<T: UITableViewHeaderFooterView>(_ aClass: T.Type) -> T! {
        let name = String(describing: aClass)
        guard let cell = dequeueReusableHeaderFooterView(withIdentifier: name) as? T else {
            fatalError("\(name) is not registed")
        }
        return cell
    }
  
}

//
//  TokenListViewController.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import UIKit
import RealmSwift

public class TokenListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var tokens: [Token] = []
    var notificationToken: NotificationToken?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TokenCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        let realm = try! Realm()
        let tokens = realm.objects(TokenEntity.self)
        notificationToken = tokens.observe({ [weak self] chains in
            self?.tokens = TokenDB.shared.allTokens()
            self?.tableView.reloadData()
        })
    }
    
    public static func create() -> UIViewController {
        return TokenListViewController.instantiateFromNib()
    }


}

extension TokenListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tokens.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TokenCell")
        cell.imageView?.loadImage(tokens[indexPath.row].iconUrl)
        cell.textLabel?.text = tokens[indexPath.row].symbol
        return cell
    }
    
}

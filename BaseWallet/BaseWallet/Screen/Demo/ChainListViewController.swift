//
//  ChainListViewController.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import UIKit
import RealmSwift
import Utilities

public class ChainListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var notificationToken: NotificationToken?
    var chains: [Chain] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChainCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        let realm = try! Realm()
        let chainResults = realm.objects(ChainObject.self)
        notificationToken = chainResults.observe({ [weak self] chains in
            self?.chains = ChainDB.shared.allChains()
            self?.tableView.reloadData()
        })
    }
    
    public static func create() -> UIViewController {
        return ChainListViewController.instantiateFromNib()
    }

}

extension ChainListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chains.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "ChainCell")
        cell.imageView?.loadImage(chains[indexPath.row].iconUrl)
        cell.textLabel?.text = chains[indexPath.row].name
        return cell
    }
    
}

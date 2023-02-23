//
//  TokenListViewController.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import UIKit
import RealmSwift
import Utilities

class BalanceViewModel {
    var token: Token
    var balance: TokenBalance
    
    init(token: Token, balance: TokenBalance) {
        self.token = token
        self.balance = balance
    }
}

public class TokenListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var balances: [TokenBalance] = []
    var notificationToken: NotificationToken?
    var viewModels: [BalanceViewModel] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TokenCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        let realm = try! Realm()
        let tokens = realm.objects(TokenBalanceEntity.self)
        notificationToken = tokens.observe({ [weak self] chains in
            self?.balances = TokenDB.shared.allBalances()
            self?.viewModels = self?.balances.compactMap { balance in
                TokenDB.shared.getToken(chainID: balance.chainID, address: balance.tokenAddress).map {
                    return BalanceViewModel(token: $0, balance: balance)
                }
            }.sorted { lhs, rhs in lhs.token.symbol < rhs.token.symbol } ?? []
            self?.tableView.reloadData()
        })
    }
    
    public static func create() -> UIViewController {
        return TokenListViewController.instantiateFromNib()
    }


}

extension TokenListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TokenCell")
        cell.imageView?.loadImage(viewModels[indexPath.row].token.iconUrl)
        cell.textLabel?.text = viewModels[indexPath.row].token.symbol
        cell.detailTextLabel?.text = NumberFormatUtils.amount(value: viewModels[indexPath.row].balance.balance,
                                                              decimals: viewModels[indexPath.row].token.decimal)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
}

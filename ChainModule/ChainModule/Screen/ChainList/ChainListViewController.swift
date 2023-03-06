//
//  ChainListViewController.swift
//  BaseWallet
//
//  Created by Tung Nguyen on 01/02/2023.
//

import UIKit
import RealmSwift
import Utilities
import Platform
import KrystalWallets

public class ChainListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var notificationToken: NotificationToken?
    var chains: [Chain] = []
    var address: KAddress!
    var showAllNetworksOption: Bool = false
    var onSelectAllNetworks: (() -> ())?
    var onSelectChainID: ((Int) -> ())?
    
    var selectedChainID: Int {
        return AppSetting.shared.int(forKey: kSelectedChainID) ?? -1
    }
    
    var isSelectingAllNetwork: Bool {
        return AppSetting.shared.bool(forKey: kIsSelectedAllNetworks)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        tableView.registerCellNib(ChainCell.self)
        tableView.registerCellNib(AddChainCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        
        let realm = try! Realm()
        let chainResults = realm.objects(ChainObject.self)
        notificationToken = chainResults.observe({ [weak self] chains in
            self?.reloadData()
        })
        self.reloadData()
    }
    
    func reloadData() {
        chains = ChainDB.shared.allChains().filter {
            if showAllNetworksOption {
                return true
            } else {
                if address.id.isEmpty {
                    return $0.id != 0
                } else {
                    return $0.id != 0 && WalletManager.shared.getAllAddresses(walletID: address.walletID).map(\.addressType).contains($0.addressType)
                }
            }
        }
        tableView.reloadData()
    }
    
    public static func create(address: KAddress, showAllNetworksOption: Bool = false, onSelectAllNetworks: (() -> ())? = nil, onSelectChainID: ((Int) -> ())?) -> UIViewController {
        let vc = ChainListViewController.instantiateFromNib()
        vc.address = address
        vc.showAllNetworksOption = showAllNetworksOption
        vc.onSelectAllNetworks = onSelectAllNetworks
        vc.onSelectChainID = onSelectChainID
        return vc
    }
    
    func handleAddChainTapped() {
        let vc = AddChainViewController.instantiateFromNib()
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension ChainListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chains.count + (showAllNetworksOption ? 1 : 0)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < chains.count {
            let cell = tableView.dequeueReusableCell(ChainCell.self, indexPath: indexPath)!
            let chainID = chains[indexPath.row].id
            let isChainSelected = isSelectingAllNetwork ? chainID == 0 : chainID == selectedChainID
            cell.configure(chain: chains[indexPath.row], isSelected: isChainSelected)
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(AddChainCell.self, indexPath: indexPath)!
            cell.selectionStyle = .none
            cell.addNetworkWasTapped = { [weak self] in
                self?.handleAddChainTapped()
            }
            return cell
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < chains.count {
            let chain = chains[indexPath.row]
            if chain.id == 0 {
                onSelectAllNetworks?()
                dismiss(animated: true)
            } else if selectedChainID != chain.id {
                onSelectChainID?(chain.id)
                dismiss(animated: true)
            }
            reloadData()
        }
    }
}

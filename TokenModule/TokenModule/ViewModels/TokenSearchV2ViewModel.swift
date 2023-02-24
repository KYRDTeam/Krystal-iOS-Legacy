//
//  TokenListViewModel.swift
//  TokenModule
//
//  Created by Tung Nguyen on 17/02/2023.
//

import Foundation
import ChainModule
import Services
import KrystalWallets
import web3
import BigInt

class TokenSearchV2ViewModel {
    var commonBaseTokens: [Services.Token] = []
    var items: [TokenItemCellViewModel] = []
    var walletAddress: String
    let chainID: Int
    var isSearchApiSupported: Bool
    let tokenService = TokenService()
    
    init(walletAddress: String, chainID: Int) {
        self.chainID = chainID
        self.isSearchApiSupported = ChainDB.shared.getConfig(chainID: chainID, key: kTokenSearchApiSupported) == "true"
        self.walletAddress = walletAddress
    }
    
    func fetchCommonBaseTokens(completion: @escaping () -> ()) {
        if let apiPath = ChainDB.shared.getConfig(chainID: chainID, key: kChainApiPath) {
            tokenService.getCommonBaseTokens(chainPath: apiPath) { tokens in
                self.commonBaseTokens = tokens
                completion()
            }
        }
    }
    
    func search(query: String, completion: @escaping () -> ()) {
        if isSearchApiSupported, let apiPath = ChainDB.shared.getConfig(chainID: chainID, key: kChainApiPath) {
            tokenService.getSearchTokens(chainPath: apiPath, address: walletAddress, query: query.trimmed, orderBy: "usdValue") { foundTokens in
                self.items = foundTokens?.map { searchToken in
                    let token = ChainModule.Token(chainID: self.chainID, address: searchToken.token.address, iconUrl: searchToken.token.logo, decimal: searchToken.token.decimals, symbol: searchToken.token.symbol, name: searchToken.token.name, tag: searchToken.token.tag ?? "", type: "erc20", isAddedByUser: false)
                    let balance = BigInt(searchToken.balance) ?? .zero
                    let price = searchToken.quotes["usd"]?.price ?? 0
                    return TokenItemCellViewModel(token: token, balance: balance, price: price)
                } ?? []
                completion()
            }
        } else {
            if query.trimmed.isEmpty {
                items = TokenDB.shared.getTokens(chainID: chainID).toViewModels(walletAddress: walletAddress)
                completion()
            } else if let chain = ChainDB.shared.getChain(byID: chainID) {
                if !WalletUtils.isAddressValid(address: query.trimmed, addressType: chain.addressType) {
                    items = TokenDB.shared.search(chainID: chainID, query: query.trimmed).toViewModels(walletAddress: walletAddress)
                    completion()
                } else {
                    getTokenInfo(address: query.trimmed) { token, balance in
                        if let token = token, let balance = balance {
                            self.items = [TokenItemCellViewModel(token: token, balance: balance, price: 0)]
                            completion()
                        } else {
                            self.items = []
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func getTokenInfo(address: String, completion: @escaping (ChainModule.Token?, BigInt?) -> ()) {
        let clients = ChainDB.shared.getTopRpcUrls(chainID: chainID).compactMap { EthereumClientFactory.shared.client(forUrl: $0) }
        let erc20 = ERC20(client: EthereumWorker(clients: clients))
        let contract = EthereumAddress(address)
        
        let dispatchGroup = DispatchGroup()
        var name: String?
        var symbol: String?
        var decimals: Int?
        var balance: BigInt?
        
        var isFailed: Bool = false
        
        dispatchGroup.enter()
        dispatchGroup.enter()
        dispatchGroup.enter()
        dispatchGroup.enter()
        
        erc20.name(tokenContract: contract) { result in
            switch result {
            case .success(let data):
                name = data
                dispatchGroup.leave()
            case .failure:
                if !isFailed {
                    isFailed = true
                    completion(nil, nil)
                }
            }
        }
        
        erc20.decimals(tokenContract: contract) { result in
            switch result {
            case .success(let data):
                decimals = Int(data)
                dispatchGroup.leave()
            case .failure:
                if !isFailed {
                    isFailed = true
                    completion(nil, nil)
                }
            }
        }
        
        erc20.symbol(tokenContract: contract) { result in
            switch result {
            case .success(let data):
                symbol = data
                dispatchGroup.leave()
            case .failure:
                if !isFailed {
                    isFailed = true
                    completion(nil, nil)
                }
            }
        }
        
        erc20.balanceOf(tokenContract: contract, address: EthereumAddress(walletAddress)) { result in
            switch result {
            case .success(let data):
                balance = BigInt(data)
                dispatchGroup.leave()
            case .failure:
                if !isFailed {
                    isFailed = true
                    completion(nil, nil)
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            guard let symbol = symbol, let decimals = decimals, let name = name, let balance = balance else {
                completion(nil, nil)
                return
            }
            let token = ChainModule.Token(chainID: self.chainID, address: address, iconUrl: "", decimal: decimals, symbol: symbol, name: name, tag: "", type: "erc20", isAddedByUser: false)
            completion(token, balance)
        }
    }
}

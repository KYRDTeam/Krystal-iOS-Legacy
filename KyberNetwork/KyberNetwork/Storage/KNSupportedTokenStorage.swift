// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift
import TrustKeystore
import TrustCore
import BigInt

class KNSupportedTokenStorage {
  
  private var supportedToken: [Token]
  private var favedTokens: [FavedToken]
  private var customTokens: [Token]
  private var disableTokens: [Token]
  private var deletedTokens: [Token]
  
  var allActiveTokens: [Token] {
    return self.getActiveSupportedToken() + self.getActiveCustomToken()
  }
  
  var allFullToken: [Token] {
    return self.supportedToken + self.customTokens
  }
  /// Tokens used for manage screen, only deactive listed tokens and all custom tokens.
  var manageToken: [Token] {
    let disableListedTokens = self.supportedToken.filter { token in
        // Only get deactive tokens
        return !self.getTokenActiveStatus(token)
    }
    return disableListedTokens.sorted(by: { $0.getBalanceBigInt() > $1.getBalanceBigInt()}) + self.getFullCustomToken().sorted(by: { $0.getBalanceBigInt() > $1.getBalanceBigInt()})
  }
  
  static let shared = KNSupportedTokenStorage()

  init() {
    self.supportedToken = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.favedTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.favedTokenStoreFileName, as: [FavedToken].self) ?? []
    self.customTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName, as: [Token].self) ?? []
    self.disableTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.disableTokenStoreFileName, as: [Token].self) ?? []
    self.deletedTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.deleteTokenStoreFileName, as: [Token].self) ?? []
    self.migrationCustomTokenIfNeeded()
  }

  //TODO: temp wrap method delete later
  var supportedTokens: [TokenObject] {
    return self.getAllTokenObject()
  }
  
  var marketTokens: [Token] {
    return self.getActiveSupportedToken()
  }

  var ethToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "ETH"
    } ?? Token(name: "Ethereum", symbol: "ETH", address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", decimals: 18, logo: "eth")
    return token.toObject()
  }

  var wethToken: TokenObject? {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "WETH"
    } ?? Token(name: "Wrapped Ether", symbol: "WETH", address: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", decimals: 18, logo: "weth")
    return token.toObject()
  }

  var kncToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "KNC"
    } ?? Token(name: "KyberNetwork", symbol: "KNC", address: "0xdefa4e8a7bcba345f687a2f1456f5edd9ce97202", decimals: 18, logo: "knc")
    return token.toObject()
  }
  
  var bnbToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "BNB"
    } ?? Token(name: "BNB", symbol: "BNB", address: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", decimals: 18, logo: "bnb")
    return token.toObject()
  }
  
  var busdToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "BUSD"
    } ?? Token(name: "BUSD", symbol: "BUSD", address: "0xe9e7cea3dedca5984780bafc599bd69add087d56", decimals: 18, logo: "")
    return token.toObject()
  }
  
  var maticToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "MATIC"
    } ?? Token(name: "MATIC", symbol: "MATIC", address: "0xcccccccccccccccccccccccccccccccccccccccc", decimals: 18, logo: "bnb")
    return token.toObject()
  }
  
  var avaxToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "AVAX"
    } ?? Token(name: "AVAX", symbol: "AVAX", address: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", decimals: 18, logo: "avax")
    return token.toObject()
  }
  
  var usdcToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "USDC"
    } ?? Token(name: "USDC", symbol: "USDC", address: "0x2791bca1f2de4661ed88a30c99a7a9449aa84174", decimals: 6, logo: "")
    return token.toObject()
  }
  
  var usdceToken: TokenObject {
    let token = self.supportedToken.first { (token) -> Bool in
      return token.symbol == "USDC.e"
    } ?? Token(name: "USDC.e", symbol: "USDC.e", address: "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664", decimals: 6, logo: "")
    return token.toObject()
  }

  func get(forPrimaryKey key: String) -> TokenObject? {
    let token = self.getTokenWith(address: key)
    return token?.toObject()
  }
  //MARK:-new data type implemetation
  func reloadData() {
    self.supportedToken = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.tokenStoreFileName, as: [Token].self) ?? []
    self.customTokens = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName, as: [Token].self) ?? []
  }

  func getSupportedTokens() -> [Token] {
    return self.supportedToken
  }

  func updateSupportedTokens(_ tokens: [Token]) {
    guard tokens != self.supportedToken else {
      return
    }
    Storage.store(tokens, as: KNEnvironment.default.envPrefix + Constants.tokenStoreFileName)
    self.supportedToken = tokens
  }

  func getTokenWith(address: String) -> Token? {
    return self.allActiveTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }
  }

  func getTokenWith(symbol: String) -> Token? {
    return self.allFullToken.first { (token) -> Bool in
      return token.symbol.lowercased() == symbol.lowercased()
    }
  }

  func getFavedTokenWithAddress(_ address: String) -> FavedToken? {
    let faved = self.favedTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }
    return faved
  }

  func getFavedStatusWithAddress(_ address: String) -> Bool {
    let faved = self.getFavedTokenWithAddress(address)
    return faved?.status ?? false
  }

  func setFavedStatusWithAddress(_ address: String, status: Bool) {
    if let faved = self.getFavedTokenWithAddress(address) {
      faved.status = status
    } else {
      let newStatus = FavedToken(address: address, status: status)
      self.favedTokens.append(newStatus)
    }
    Storage.store(self.favedTokens, as: KNEnvironment.default.envPrefix + Constants.favedTokenStoreFileName)
  }
  
  func saveCustomToken(_ token: Token) {
    self.customTokens.append(token)
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
  }

  func isTokenSaved(_ token: Token) -> Bool {
    let tokens = self.allActiveTokens
    let saved = tokens.first { (item) -> Bool in
      return item.address.lowercased() == token.address.lowercased()
    }

    return saved != nil
  }

  func getActiveCustomToken() -> [Token] {
    return self.customTokens.filter { token in
      return self.getTokenActiveStatus(token) && !self.getTokenDeleteStatus(token) && !token.symbol.isEmpty
    }
  }
  
  func getActiveSupportedToken() -> [Token] {
    return self.supportedToken.filter { token in
      return self.getTokenActiveStatus(token) && !self.getTokenDeleteStatus(token)
    }
  }
  
  func getFullCustomToken() -> [Token] {
    return self.customTokens.filter { token in
      return !self.getTokenDeleteStatus(token) && !token.symbol.isEmpty
    }
  }

  func getCustomTokenWith(address: String) -> Token? {
    return self.customTokens.first { (token) -> Bool in
      return token.address.lowercased() == address.lowercased()
    }
  }
  
  func getTokenDeleteStatus(_ token: Token) -> Bool {
    return self.deletedTokens.contains(token)
  }
  
  func removeTokenFromDeleteList(_ token: Token) {
    if let index = self.deletedTokens.firstIndex(where: { item in
      return item == token
    }) {
      self.deletedTokens.remove(at: index)
    }
  }
  
  func getTokenActiveStatus(_ token: Token) -> Bool {
    return !self.disableTokens.contains(token)
  }

  func setTokenActiveStatus(token: Token, status: Bool) {
    if status {
      if let index = self.disableTokens.firstIndex(where: { item in
        return item == token
      }) {
        self.disableTokens.remove(at: index)
        Storage.store(self.disableTokens, as: KNEnvironment.default.envPrefix + Constants.disableTokenStoreFileName)
      }
    } else {
      if !self.disableTokens.contains(token) {
        self.disableTokens.append(token)
        Storage.store(self.disableTokens, as: KNEnvironment.default.envPrefix + Constants.disableTokenStoreFileName)
      }
    }
  }
  
  func changeAllTokensActiveStatus(isActive: Bool) {
    self.disableTokens.removeAll()
    if !isActive {
      self.disableTokens.append(contentsOf: manageToken)
    }
    Storage.store(self.disableTokens, as: KNEnvironment.default.envPrefix + Constants.disableTokenStoreFileName)
  }
  
  func activeStatus() -> Bool {
    if disableTokens.isEmpty {
      // all tokens are active
      return true
    }
    
    if manageToken.count == disableTokens.count {
      // all tokens are deactive
      return false
    }
    
    if manageToken.count / 2 > disableTokens.count {
      // more than half of manage token are active
      return true
    }
    // more than half of manage token are deactive
    return false
  }
  
  func deleteCustomToken(_ token: Token) {
    guard !self.deletedTokens.contains(token) else {
      return
    }
    
    self.deletedTokens.append(token)
    Storage.store(self.self.deletedTokens, as: KNEnvironment.default.envPrefix + Constants.deleteTokenStoreFileName)
  }
  
  func editCustomToken(address: String, newAddress: String, symbol: String, decimal: Int) {
    guard let token = self.getCustomTokenWith(address: address) else { return }
    token.address = newAddress
    token.symbol = symbol
    token.decimals = decimal
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
  }

  func getAllTokenObject() -> [TokenObject] {
    return self.getListedTokenObject() + self.getCustomTokenObject()
  }

  func getListedTokenObject() -> [TokenObject] {
    let activeTokens = self.supportedToken.filter { token in
        // Only get active tokens
        return self.getTokenActiveStatus(token)
    }
    return activeTokens.map { (token) -> TokenObject in
        return token.toObject()
    }
  }

  func getCustomTokenObject() -> [TokenObject] {
    return self.getActiveCustomToken().map { (token) -> TokenObject in
        return token.toObject(isCustom:true)
    }
  }

  func getETH() -> Token {
    return self.supportedToken.first { (item) -> Bool in
      return item.symbol == "ETH"
    } ?? Token(name: "Ethereum", symbol: "ETH", address: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee", decimals: 18, logo: "eth")
  }
  
  func getKNC() -> Token {
    return self.supportedToken.first { (item) -> Bool in
      return item.symbol == "KNC"
    } ?? Token(name: "KyberNetwork", symbol: "KNC", address: "0x7b2810576aa1cce68f2b118cef1f36467c648f92", decimals: 18, logo: "knc")
  }
  
//  func checkAddCustomTokenIfNeeded() {
//    var unknown: [Token] = []
//    let all = self.allTokens
//    guard !all.isEmpty else {
//      return
//    }
//    let etherscanTokens = EtherscanTransactionStorage.shared.getEtherscanToken()
//    etherscanTokens.forEach { (token) in
//      if !all.contains(token) {
//        unknown.append(token)
//      }
//    }
//    guard !unknown.isEmpty else {
//      return
//    }
//    var customTokenCache = self.customTokens
//    unknown.forEach { (token) in
//      if !customTokenCache.contains(token) {
//        customTokenCache.append(token)
//      }
//    }
//
//    //Check duplicate with support token list
//    var duplicateToken: [Token] = []
//    customTokenCache.forEach { (token) in
//      if self.supportedToken.contains(token) {
//        duplicateToken.append(token)
//      }
//    }
//    duplicateToken.forEach { (token) in
//      if let idx = customTokenCache.firstIndex(where: { $0 == token }) {
//        customTokenCache.remove(at: idx)
//      }
//    }
//
//    self.customTokens = customTokenCache
//    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
//  }
  
  func checkAddCustomTokenIfNeeded(_ tokens: [Token]) {
    guard !self.supportedToken.isEmpty else {
      return
    }
    let all = self.allFullToken
    let customs = self.customTokens
    var unknown: [Token] = []
    var duplicated: [Token] = []
    tokens.forEach { token in
      if !all.contains(token) {
        unknown.append(token)
      } else {
        if customs.contains(token) && self.supportedToken.contains(token) {
          duplicated.append(token)
        }
      }
    }
    guard !unknown.isEmpty else {
      return
    }
    self.customTokens.append(contentsOf: unknown)
    if !duplicated.isEmpty {
      duplicated.forEach { item in
        if let idx = customTokens.firstIndex(of: item) {
          self.customTokens.remove(at: idx)
        }
      }
    }
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
  }

  func migrationCustomTokenIfNeeded() {
    guard KNGeneralProvider.shared.currentChain == .eth, Storage.isFileExistAtPath(Constants.customTokenStoreFileName) else {
      return
    }
    let token = Storage.retrieve(Constants.customTokenStoreFileName, as: [Token].self) ?? []
    guard !token.isEmpty else {
      return
    }
    let all = self.allFullToken
    var add: [Token] = []
    token.forEach { (item) in
      if !all.contains(item) {
        add.append(item)
      }
    }
    self.customTokens.append(contentsOf: add)
    Storage.removeFileAtPath(Constants.customTokenStoreFileName)
    Storage.store(self.customTokens, as: KNEnvironment.default.envPrefix + Constants.customTokenStoreFileName)
  }
  
  func getAssetTokens() -> [Token] {
    var result: [Token] = []
    let tokens = KNSupportedTokenStorage.shared.allActiveTokens
    let lendingBalances = BalanceStorage.shared.getAllLendingBalances()
    var lendingSymbols: [String] = []
    lendingBalances.forEach { (lendingPlatform) in
      lendingPlatform.balances.forEach { (balance) in
        lendingSymbols.append(balance.interestBearingTokenSymbol.lowercased())
      }
    }
    tokens.forEach { (token) in
      guard token.getBalanceBigInt() > BigInt(0), !lendingSymbols.contains(token.symbol.lowercased()) else {
        return
      }
      result.append(token)
    }
    return result
  }
  
  func findTokensWithAddresses(addresses: [String]) -> [Token] {
    return self.allActiveTokens.filter { (token) -> Bool in
      return addresses.contains(token.address.lowercased())
    }
  }
  
}


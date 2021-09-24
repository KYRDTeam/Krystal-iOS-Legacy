// Copyright SIX DAY LLC. All rights reserved.

import BigInt
import JSONRPCKit
import APIKit
import Result
import TrustKeystore
import TrustCore
import JavaScriptKit
import CryptoSwift

enum ChainType: Codable {
  enum Key: CodingKey {
    case rawValue
  }
  
  enum CodingError: Error {
    case unknownValue
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Key.self)
    let rawValue = try container.decode(Int.self, forKey: .rawValue)
    switch rawValue {
    case 0:
      self = .eth
    case 1:
      self = .bsc
    case 2:
      self = .polygon
    case 3:
      self = .avalanche
    default:
      throw CodingError.unknownValue
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Key.self)
    switch self {
    case .eth:
      try container.encode(0, forKey: .rawValue)
    case .bsc:
      try container.encode(1, forKey: .rawValue)
    case .polygon:
      try container.encode(2, forKey: .rawValue)
    case .avalanche:
      try container.encode(3, forKey: .rawValue)
    }
  }
  
  case eth
  case bsc
  case polygon
  case avalanche
}
//swiftlint:disable file_length
//swiftlint:disable type_body_length
class KNGeneralProvider {

  static let shared = KNGeneralProvider()
  
  var currentChain: ChainType {
    didSet {
      Storage.store(self.currentChain, as: Constants.currentChainSaveFileName)
    }
  }
  
  var customRPC: CustomRPC {
    switch self.currentChain {
    case .eth:
      return KNEnvironment.default.ethRPC
    case .bsc:
      return KNEnvironment.default.bscRPC
    case .polygon:
      return KNEnvironment.default.maticRPC
    case .avalanche:
      return KNEnvironment.default.avalancheRPC
    }
  }
  
  var currentWeb3: Web3Swift = Web3Swift()
  
  var quoteToken: String {
    switch self.currentChain {
    case .eth:
      return "ETH"
    case .bsc:
      return "BNB"
    case .polygon:
      return "MATIC"
    case .avalanche:
      return "AVAX"
    }
  }
  
  var quoteCurrency: CurrencyMode {
    switch self.currentChain {
    case .eth:
      return .eth
    case .bsc:
      return .bnb
    case .polygon:
      return .matic
    case .avalanche:
      return .avax
    }
  }
  
  var chainPath: String {
    switch self.currentChain {
    case .eth:
      if KNEnvironment.default == .ropsten {
        return "/ropsten"
      }
      return "/ethereum"
    case .bsc:
      if KNEnvironment.default == .ropsten {
        return "/bsctestnet"
      }
      return "/bsc"
    case .polygon:
      if KNEnvironment.default == .ropsten {
        return "/mumbai"
      }
      return "/polygon"
    case .avalanche:
      return "/avalanche"
    }
  }
  
  var quoteTokenObject: TokenObject {
    switch self.currentChain {
    case .eth:
      return KNSupportedTokenStorage.shared.ethToken
    case .bsc:
      return KNSupportedTokenStorage.shared.bnbToken
    case .polygon:
      return KNSupportedTokenStorage.shared.maticToken
    case .avalanche:
      return KNSupportedTokenStorage.shared.avaxToken
    }
  }
  
  var quoteTokenPrice: TokenPrice? {
    switch self.currentChain {
    case .eth:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.ethAddress)
    case .bsc:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.bnbAddress)
    case .polygon:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.maticAddress)
    case .avalanche:
      return KNTrackerRateStorage.shared.getPriceWithAddress(Constants.avaxAddress)
    }
  }
  
  var chainIconImage: UIImage? {
    switch self.currentChain {
    case .eth:
      return UIImage(named: "chain_eth_icon")
    case .bsc:
      return UIImage(named: "chain_bsc_icon")
    case .polygon:
      return UIImage(named: "chain_polygon_big_icon")
    case .avalanche:
      return UIImage(named: "chain_avax_icon")
    }
  }
  
  var proxyAddress: String {
    switch self.currentChain {
    case .eth:
      return Constants.krystalProxyAddress.lowercased()
    case .bsc:
      return Constants.krystalProxyAddressBSC.lowercased()
    case .polygon:
      return Constants.krystalProxyAddressMatic.lowercased()
    case .avalanche:
      return Constants.krystalProxyAddressAvax.lowercased()
    }
  }
  
  var compoundSymbol: String {
    switch self.currentChain {
    case .eth:
      return "COMP"
    case .bsc:
      return "XVS"
    case .polygon:
      return "COMP"
    case .avalanche:
      return "" //TODO: wait for compound symbol
    }
  }
  
  var compoundImageIcon: UIImage? {
    switch self.currentChain {
    case .eth:
      return UIImage(named: "comp_icon")
    case .bsc:
      return UIImage(named: "venus_icon")
    case .polygon:
      return UIImage(named: "comp_icon")
    case .avalanche:
      return UIImage(named: "") //TODO: wait for compound icon
    }
  }
  
  var tokenType: String {
    switch self.currentChain {
    case .eth:
      return "ERC20"
    case .bsc:
      return "BEP20"
    case .polygon:
      return "ERC20"
    case .avalanche:
      return "ARC20"
    }
  }
  
  var apiKey: String {
    switch self.currentChain {
    case .eth:
      return KNSecret.etherscanAPIKey
    case .bsc:
      return KNSecret.bscscanAPIKey
    case .polygon:
      return KNSecret.polygonscanAPIKey
    case .avalanche:
      return "" //TODO: wait for avalance api key
    }
  }
  
  var lendingDistributionPlatform: String {
    switch self.currentChain {
    case .eth:
      return "Compound"
    case .bsc:
      return "Venus"
    case .polygon:
      return ""
    case .avalanche:
      return ""
    }
  }
  
  var chainName: String {
    switch self.currentChain {
    case .eth:
      return "Ethereum"
    case .bsc:
      return "Binance Smart Chain"
    case .polygon:
      return "Polygon"
    case .avalanche:
      return "Avalanche"
    }
  }
  
  var priceAlertMessage: String {
    switch self.currentChain {
    case .eth:
      return "There.is.a.difference.between.the.estimated.price"
    case .bsc:
      return "There.is.a.difference.between.the.estimated.price.bsc"
    case .polygon:
      return "There.is.a.difference.between.the.estimated.price.matic"
    case .avalanche:
      return "There.is.a.difference.between.the.estimated.price.avalanche"
    }
  }

  var web3Swift: Web3Swift {
    if let path = URL(string: self.customRPC.endpoint + KNEnvironment.default.nodeEndpoint) {
      let web3 = Web3Swift(url: path)
      if web3.url != self.currentWeb3.url {
        self.currentWeb3 = web3
        DispatchQueue.main.async {
          self.currentWeb3.start()
        }
      }
      return self.currentWeb3
    } else {
      return Web3Swift()
    }
  }

  var web3SwiftKyber: Web3Swift {
    if let path = URL(string: self.customRPC.endpointKyber + KNEnvironment.default.nodeEndpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }

  var web3SwiftAlchemy: Web3Swift  {
    if let path = URL(string: self.customRPC.endpointAlchemy + KNEnvironment.default.nodeEndpoint) {
      return Web3Swift(url: path)
    } else {
      return Web3Swift()
    }
  }

  var networkAddress: Address {
    var address = ""
    switch self.currentChain {
    case .eth:
      address = Constants.krystalProxyAddress.lowercased()
    case .bsc:
      address = Constants.krystalProxyAddressBSC.lowercased()
    case .polygon:
      address = Constants.krystalProxyAddressMatic.lowercased()
    case .avalanche:
      address = Constants.krystalProxyAddressAvax.lowercased()
    }
    return Address(string: address)!
  }

  var wrapperAddress: Address {
    return Address(string: self.customRPC.wrappedAddress)!
  }

  init() {
    if let saved = Storage.retrieve(Constants.currentChainSaveFileName, as: ChainType.self) {
      self.currentChain = saved
    } else {
      self.currentChain = .eth
    }
  }

  // MARK: Balance
  func getETHBalanace(for address: String, completion: @escaping (Result<Balance, AnyError>) -> Void) {
    DispatchQueue.global().async {
      let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(BalanceRequest(address: address)))
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let balance):
            completion(.success(balance))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func getGasPrice(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(GasPriceRequest()))
    Session.send(request) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let gasPrice):
          completion(.success(gasPrice))
        case .failure(let error):
          completion(.failure(AnyError(error)))
        }
      }
    }
  }

  func getTokenBalance(for address: Address, contract: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getTokenBalanceEncodeData(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: contract.description, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let balance):
                self.getTokenBalanceDecodeData(from: balance, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getNFTBalance(for address: String, id: String, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    
    self.getNFTBalanceEncodeData(for: address, id: id) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: contract, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let balance):
                self.getNFTBalanceDecodeData(from: balance, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getTokenSymbol(address: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getSymbolEncodeData { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: address, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let symbol):
                self.getTokenSymbolDecodeData(from: symbol, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getERC721Name(address: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getERC721NameEncodeData { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: address, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let symbol):
                self.getERC721NameDecodeData(from: symbol, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getTokenDecimals(address: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getDecimalsEncodeData { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: address, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let decimals):
                self.getTokenDecimalsDecodeData(from: decimals, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getOwnerOf(address: String, id: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    self.getOwnerOfEncodeData(id: id) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: address, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let data):
                self.getOwnerOfDecodeData(from: data, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getSupportInterface(address: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    self.getSupportInterfaceEncodeData { encodeResult in
      switch encodeResult {
      case .success(let data):
        let request = EtherServiceAlchemyRequest(
          batch: BatchFactory().create(CallRequest(to: address, data: data))
        )
        DispatchQueue.global().async {
          Session.send(request) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let value):
                self.getSupportInterfaceDecodeData(from: value, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getMutipleERC20Balances(for address: Address, tokens: [Address], completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    let data = "0x6a385ae9"
      + "000000000000000000000000\(address.description.lowercased().drop0x)"
      + "0000000000000000000000000000000000000000000000000000000000000040"
    var tokenCount = BigInt(tokens.count).hexEncoded.drop0x
    tokenCount = [Character].init(repeating: "0", count: 64 - tokenCount.count) + tokenCount
    let tokenAddresses = tokens.map({ return "000000000000000000000000\($0.description.lowercased().drop0x)" }).joined(separator: "")
    let request = EtherServiceAlchemyRequest(
      batch: BatchFactory().create(CallRequest(to: self.wrapperAddress.description, data: "\(data)\(tokenCount)\(tokenAddresses)"))
    )
    print("\(data)\(tokenCount)\(tokenAddresses)")
    DispatchQueue.global().async {
      Session.send(request) { [weak self] result in
        guard let `self` = self else { return }
        DispatchQueue.main.async {
          switch result {
          case .success(let data):
            self.getMultipleERC20BalancesDecode(data: data, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  // MARK: Transaction count
  func getTransactionCount(for address: String, state: String = "latest", completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EtherServiceAlchemyRequest(batch: BatchFactory().create(GetTransactionCountRequest(
      address: address,
      state: state
    )))
    DispatchQueue.global().async {
      Session.send(request) { result in
        DispatchQueue.main.async {
          switch result {
          case .success(let count):
//            minTxCount = max(minTxCount, count)
            completion(.success(count))
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }

  func getAllowance(for address: Address, networkAddress: Address, tokenAddress: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if tokenAddress == Address(string: "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee") {
      // ETH no need to request for approval
      completion(.success(BigInt(2).power(255)))
      return
    }
    self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { [weak self] dataResult in
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: tokenAddress.description, data: data)
        let getAllowanceRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getAllowanceRequest) { [weak self] getAllowanceResult in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch getAllowanceResult {
              case .success(let data):
                self.getTokenAllowanceDecodeData(data, completion: completion)
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getAllowance(for token: TokenObject, address: Address, networkAddress: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if token.isETH || token.isBNB {
      // ETH no need to request for approval
      completion(.success(BigInt(2).power(255)))
      return
    }
    let tokenAddress: Address = Address(string: token.contract)!
    self.getAllowance(for: address, networkAddress: networkAddress, tokenAddress: tokenAddress, completion: completion)
  }

  func getExpectedRate(from: TokenObject, to: TokenObject, amount: BigInt, hint: String = "", withKyber: Bool = false, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let source: Address = Address(string: from.contract)!
    let dest: Address = Address(string: to.contract)!
    self.getExpectedRateEncodeData(source: source, dest: dest, amount: amount, hint: hint) { [weak self] dataResult in
      guard let `self` = self else { return }
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: self.networkAddress.description, data: data)
        if withKyber {
          let getRateRequest = EtherServiceKyberRequest(batch: BatchFactory().create(callRequest))
          DispatchQueue.global().async {
            Session.send(getRateRequest) { [weak self] getRateResult in
              guard let `self` = self else { return }
              DispatchQueue.main.async {
                switch getRateResult {
                case .success(let rateData):
                  self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
                case .failure(let error):
                  completion(.failure(AnyError(error)))
                }
              }
            }
          }
        } else {
          let getRateRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
          DispatchQueue.global().async {
            Session.send(getRateRequest) { [weak self] getRateResult in
              guard let `self` = self else { return }
              DispatchQueue.main.async {
                switch getRateResult {
                case .success(let rateData):
                  self.getExpectedRateDecodeData(rateData: rateData, completion: completion)
                case .failure(let error):
                  completion(.failure(AnyError(error)))
                }
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getResolverAddress(_ ensName: String, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    self.getResolverEncode(name: ensName) { result in
      switch result {
      case .success(let resp):
        let callRequest = CallRequest(
          to: KNGeneralProvider.shared.customRPC.ensAddress,
          data: resp
        )
        let getResolverRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getResolverRequest) { getResolverResult in
            DispatchQueue.main.async {
              switch getResolverResult {
              case .success(let data):
                if data == "0x" {
                  completion(.success(nil))
                  return
                }
                let idx = data.index(data.endIndex, offsetBy: -40)
                let resolverAddress = String(data[idx...]).add0x
                completion(.success(Address(string: resolverAddress)))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getAddressFromResolver(_ ensName: String, resolverAddress: Address, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    self.getAddressFromResolverEncode(name: ensName) { result in
      switch result {
      case .success(let resp):
        let callRequest = CallRequest(
          to: resolverAddress.description,
          data: resp
        )
        let getResolverRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest))
        DispatchQueue.global().async {
          Session.send(getResolverRequest) { getResolverResult in
            DispatchQueue.main.async {
              switch getResolverResult {
              case .success(let data):
                if data == "0x" {
                  completion(.success(nil))
                  return
                }
                let idx = data.index(data.endIndex, offsetBy: -40)
                let address = String(data[idx...]).add0x
                completion(.success(Address(string: address)))
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getAddressByEnsName(_ name: String, completion: @escaping (Result<Address?, AnyError>) -> Void) {
    KNGeneralProvider.shared.getResolverAddress(name) { result in
      switch result {
      case .success(let resolverAddr):
        guard let addr = resolverAddr else {
          completion(.success(nil))
          return
        }
        KNGeneralProvider.shared.getAddressFromResolver(name, resolverAddress: addr) { result2 in
          switch result2 {
          case .success(let finalAddr):
            completion(.success(finalAddr))
          case .failure(let error):
            completion(.failure(error))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func approve(token: TokenObject, value: BigInt = BigInt(2).power(256) - BigInt(1), account: Account, keystore: Keystore, currentNonce: Int, networkAddress: Address, gasPrice: BigInt, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    self.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, value: value, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    self.getTransactionCount(for: account.address.description) { result in
      switch result {
      case .success(let resp):
        txCount = max(resp, currentNonce)
      case .failure(let err):
        error = err
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }

      guard let tokenAddress = Address(string: token.contract) else { return }
      self.signTransactionData(forApproving: tokenAddress, account: account, nonce: txCount, data: encodeData, keystore: keystore, gasPrice: gasPrice) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signData):
          self.sendSignedTransactionData(signData.0, completion: { sendResult in
            switch sendResult {
            case .success(let hash):
              var symbol = KNSupportedTokenStorage.shared.getTokenWith(address: tokenAddress.description.lowercased())?.name ?? "Token"
              if tokenAddress.description.lowercased() == Constants.gasTokenAddress {
                symbol = "CHI"
              }
              let historyTransaction = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: symbol, transactionDetailDescription: tokenAddress.description, transactionObj: signData.1.toSignTransactionObject())
              historyTransaction.hash = hash
              historyTransaction.time = Date()
              historyTransaction.nonce = txCount
              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
              completion(.success(txCount + 1))
            case .failure(let error):
              completion(.failure(error))
            }
          })
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }
  
  func approve(tokenAddress: Address, value: BigInt = BigInt(2).power(256) - BigInt(1), account: Account, keystore: Keystore, currentNonce: Int, networkAddress: Address, gasPrice: BigInt, completion: @escaping (Result<Int, AnyError>) -> Void) {
    var error: Error?
    var encodeData: Data = Data()
    var txCount: Int = 0
    let group = DispatchGroup()

    group.enter()
    self.getSendApproveERC20TokenEncodeData(networkAddress: networkAddress, value: value, completion: { result in
      switch result {
      case .success(let resp):
        encodeData = resp
      case .failure(let err):
        error = err
      }
      group.leave()
    })
    group.enter()
    self.getTransactionCount(for: account.address.description) { result in
      switch result {
      case .success(let resp):
        txCount = max(resp, currentNonce)
      case .failure(let err):
        error = err
      }
      group.leave()
    }

    group.notify(queue: .main) {
      if let error = error {
        completion(.failure(AnyError(error)))
        return
      }
      self.signTransactionData(forApproving: tokenAddress, account: account, nonce: txCount, data: encodeData, keystore: keystore, gasPrice: gasPrice) { [weak self] result in
        guard let `self` = self else { return }
        switch result {
        case .success(let signData):
          self.sendSignedTransactionData(signData.0, completion: { sendResult in
            switch sendResult {
            case .success(let hash):
              var symbol = KNSupportedTokenStorage.shared.getTokenWith(address: tokenAddress.description.lowercased())?.name ?? "Token"
              if tokenAddress.description.lowercased() == Constants.gasTokenAddress {
                symbol = "CHI"
              }
              let historyTransaction = InternalHistoryTransaction(type: .allowance, state: .pending, fromSymbol: "", toSymbol: "", transactionDescription: symbol, transactionDetailDescription: tokenAddress.description, transactionObj: signData.1.toSignTransactionObject())
              historyTransaction.hash = hash
              historyTransaction.time = Date()
              historyTransaction.nonce = txCount
              EtherscanTransactionStorage.shared.appendInternalHistoryTransaction(historyTransaction)
              completion(.success(txCount + 1))
            case .failure(let error):
              completion(.failure(error))
            }
          })
        case .failure(let error):
          completion(.failure(error))
        }
      }
    }
  }

  public func getUserCapInWei(for address: Address, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getUserCapInWeiEncode(for: address) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let callReq = CallRequest(
          to: self.networkAddress.description,
          data: data
        )
        let ethService = EtherServiceAlchemyRequest(batch: BatchFactory().create(callReq))
        DispatchQueue.global(qos: .background).async {
          Session.send(ethService) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
              switch result {
              case .success(let resp):
                self.getUserCapInWeiDecode(from: resp, completion: { decodeResult in
                  switch decodeResult {
                  case .success(let value):
                    completion(.success(value))
                  case .failure(let error):
                    completion(.failure(error))
                  }
                })
              case .failure(let error):
                completion(.failure(AnyError(error)))
              }
            }
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func sendSignedTransactionData(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    var error: Error?
    var transactionID: String?
    var hasCompletionCalled: Bool = false
    let group = DispatchGroup()
    group.enter()
    self.sendRawTransactionWithInfura(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
        print(error.debugDescription)
      }
      group.leave()
    }
    group.enter()
    self.sendRawTransactionWithAlchemy(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
      }
      group.leave()
    }
    group.enter()
    self.sendRawTransactionWithKyber(data) { [weak self] result in
      guard let _ = self else { return }
      switch result {
      case .success(let ID):
        transactionID = ID
        if !hasCompletionCalled {
          hasCompletionCalled = true
          completion(.success(ID))
        }
      case .failure(let er):
        error = er
      }
      group.leave()
    }
    group.notify(queue: .main) {
      if let id = transactionID {
        if !hasCompletionCalled { completion(.success(id)) }
      } else if let err = error {
        completion(.failure(AnyError(err)))
      }
    }
  }

  private func sendRawTransactionWithInfura(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func sendRawTransactionWithAlchemy(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceAlchemyRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  private func sendRawTransactionWithKyber(_ data: Data, completion: @escaping (Result<String, AnyError>) -> Void) {
    let batch = BatchFactory().create(SendRawTransactionRequest(signedTransaction: data.hexEncoded))
    let request = EtherServiceKyberRequest(batch: batch)
    Session.send(request) { result in
      switch result {
      case .success(let transactionID):
        completion(.success(transactionID))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Sign transaction
extension KNGeneralProvider {
  private func signTransactionData(forApproving token: TokenObject, account: Account, nonce: Int, data: Data, keystore: Keystore, gasPrice: BigInt, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let gasLimit: BigInt = {
      if let gasApprove = token.gasApproveDefault { return gasApprove }
      return KNGasConfiguration.approveTokenGasLimitDefault
    }()
    let signTransaction = SignTransaction(
      value: BigInt(0),
      account: account,
      to: Address(string: token.contract),
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    let signResult = keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success(data))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }

  private func signTransactionData(forApproving tokenAddress: Address, account: Account, nonce: Int, data: Data, keystore: Keystore, gasPrice: BigInt, completion: @escaping (Result<(Data, SignTransaction), AnyError>) -> Void) {
    let gasLimit: BigInt = KNGasConfiguration.approveTokenGasLimitDefault
    let signTransaction = SignTransaction(
      value: BigInt(0),
      account: account,
      to: tokenAddress,
      nonce: nonce,
      data: data,
      gasPrice: gasPrice,
      gasLimit: gasLimit,
      chainID: KNGeneralProvider.shared.customRPC.chainID
    )
    let signResult = keystore.signTransaction(signTransaction)
    switch signResult {
    case .success(let data):
      completion(.success((data, signTransaction)))
    case .failure(let error):
      completion(.failure(AnyError(error)))
    }
  }
}

// MARK: Web3Swift Encoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceEncodeData(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20BalanceEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getNFTBalanceEncodeData(for address: String, id: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC721BalanceEncode(address: address, id: id)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getOwnerOfEncodeData(id: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC1155OwnerOfEncode(id: id)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getSymbolEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20SymbolEncode()
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getERC721NameEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC721NameEncode()
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func getDecimalsEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20DecimalsEncode()
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getSupportInterfaceEncodeData(completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetSupportInterfaceEncode()
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getSendApproveERC20TokenEncodeData(networkAddress: Address, value: BigInt = BigInt(2).power(256) - BigInt(1), completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = ApproveERC20Encode(
      address: networkAddress,
      value: value
    )
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceEncodeData(for address: Address, networkAddress: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetTokenAllowanceEndcode(
      ownerAddress: address,
      spenderAddress: networkAddress
    )
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getExpectedRateEncodeData(source: Address, dest: Address, amount: BigInt, hint: String = "", completion: @escaping (Result<String, AnyError>) -> Void) {
    let encodeRequest = KNGetExpectedRateEncode(source: source, dest: dest, amount: amount, hint: hint)
    self.web3Swift.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getUserCapInWeiEncode(for address: Address, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetUserCapInWeiEncode(address: address)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getResolverEncode(name: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetResolverRequest(nameHash: self.nameHash(name: name))
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getAddressFromResolverEncode(name: String, completion: @escaping (Result<String, AnyError>) -> Void) {
     let request = KNGetAddressFromResolverRequest(nameHash: self.nameHash(name: name))
     self.web3Swift.request(request: request) { result in
       switch result {
       case .success(let data):
         completion(.success(data))
       case .failure(let error):
         completion(.failure(AnyError(error)))
       }
     }
   }

  fileprivate func nameHash(name: String) -> String {
    var node = Data.init(count: 32)
    let labels = name.components(separatedBy: ".")
    for label in labels.reversed() {
      let data = Data(bytes: SHA3(variant: .keccak256).calculate(for: label.bytes))
      node.append(data)
      node = Data(bytes: SHA3(variant: .keccak256).calculate(for: node.bytes))
    }
    return node.hexEncoded
  }

  fileprivate func getMutipleERC20BalancesEncode(from address: Address, tokens: [Address], completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetMultipleERC20BalancesEncode(address: address, tokens: tokens)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

// MARK: Web3Swift Decoding
extension KNGeneralProvider {
  fileprivate func getTokenBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let request = GetERC20BalanceDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getNFTBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let request = GetERC721BalanceDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getTokenSymbolDecodeData(from symbol: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20SymbolDecode(data: symbol)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getERC721NameDecodeData(from symbol: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC721SymbolDecode(data: symbol)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getTokenDecimalsDecodeData(from decimals: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC20DecimalsDecode(data: decimals)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getOwnerOfDecodeData(from data: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC1155OwnerOfDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getSupportInterfaceDecodeData(from value: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    let request = GetSupportInterfaceDecode(data: value)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(res))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  fileprivate func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if data == "0x" {
      // Fix: Can not decode 0x to uint
      completion(.success(BigInt(0)))
      return
    }
    let decodeRequest = KNGetTokenAllowanceDecode(data: data)
    self.web3Swift.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(remain))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getExpectedRateDecodeData(rateData: String, completion: @escaping (Result<(BigInt, BigInt), AnyError>) -> Void) {
    let decodeRequest = KNGetExpectedRateWithFeeDecode(data: rateData)
    self.web3Swift.request(request: decodeRequest, completion: { (result) in
      switch result {
      case .success(let expectedRateData):
        let expectedRate: BigInt = BigInt(expectedRateData) ?? BigInt(0)
        let slippageRate: BigInt = expectedRate * BigInt(97) / BigInt(100)
        completion(.success((expectedRate, slippageRate)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }

  fileprivate func getUserCapInWeiDecode(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let request = KNGetUserCapInWeiDecode(data: balance)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt(0)))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }

  func getMultipleERC20BalancesDecode(data: String, completion: @escaping (Result<[BigInt], AnyError>) -> Void) {
    let request = GetMultipleERC20BalancesDecode(data: data)
    self.web3Swift.request(request: request) { result in
      switch result {
      case .success(let data):
        let res = data.map({ val -> BigInt in
          if val == "0x" { return BigInt(0) }
          return BigInt(val) ?? BigInt(0)
        })
        completion(.success(res))
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getEstimateGasLimit(transaction: SignTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: transaction.account.address.description,
      to: transaction.to?.description,
      value: transaction.value,
      data: transaction.data,
      gasPrice: transaction.gasPrice
    )
    Session.send(EtherServiceAlchemyRequest(batch: BatchFactory().create(request))) { result in
      switch result {
      case .success(let value):
        let limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
        completion(.success(limit))
      case .failure(let error):
        NSLog("------ Estimate gas used failed: \(error.localizedDescription) ------")
        completion(.failure(AnyError(error)))
      }
    }
  }
}

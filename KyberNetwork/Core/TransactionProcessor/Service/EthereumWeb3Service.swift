//
//  EthereumWeb3Service.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 13/06/2022.
//

import Foundation
import BigInt
import Result
import APIKit
import JSONRPCKit

class EthereumWeb3Service {
  
  let web3: Web3Swift?
  let chain: ChainType
  
  var baseURL: URL? {
    return URL(string: self.chain.customRPC().endpointAlchemy)
  }
  
  init(chain: ChainType) {
    self.chain = chain
    self.web3 = Web3Factory.shared.web3Instance(forChain: chain)
  }
  
  func getTransferTokenData(transferQuoteToken: Bool, amount: BigInt, address: String, completion: @escaping (Result<Data, AnyError>) -> Void) {
    web3?.request(request: ContractERC20Transfer(amount: amount, address: address)) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getAllowance(for address: String, networkAddress: String, tokenAddress: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if tokenAddress == chain.quoteTokenObject().address {
      completion(.success(BigInt(2).power(255)))
      return
    }
    self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { dataResult in
      switch dataResult {
      case .success(let data):
        let callRequest = CallRequest(to: tokenAddress, data: data)
        let request = EthereumNodeRequest(
          batch: BatchFactory().create(callRequest),
          nodeURL: self.baseURL
        )
        Session.send(request) { getAllowanceResult in
          switch getAllowanceResult {
          case .success(let data):
            self.getTokenAllowanceDecodeData(data, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getTokenAllowanceEncodeData(for address: String, networkAddress: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = KNGetTokenAllowanceEndcode(ownerAddress: address, spenderAddress: networkAddress)
    web3?.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if data == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let decodeRequest = KNGetTokenAllowanceDecode(data: data)
    web3?.request(request: decodeRequest, completion: { decodeResult in
      switch decodeResult {
      case .success(let value):
        let remain: BigInt = BigInt(value) ?? BigInt(0)
        completion(.success(remain))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    })
  }
  
  func getTransactionCount(for address: String, state: String = "latest", completion: @escaping (Result<Int, AnyError>) -> Void) {
    let request = EthereumNodeRequest(
      batch: BatchFactory().create(GetTransactionCountRequest(address: address, state: state)),
      nodeURL: baseURL
    )
    Session.send(request) { result in
      switch result {
      case .success(let count):
        let currentNonce = NonceCache.shared.getCachingNonce(address: address, chain: self.chain)
        NonceCache.shared.updateNonce(address: address, chain: self.chain, nonce: max(count, currentNonce))
        completion(.success(count))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func estimateGasLimit(from: String, to: String?, gasPrice: BigInt, value: BigInt, data: Data, defaultGasLimit: BigInt, isSwap: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: from,
      to: to,
      value: value,
      data: data,
      gasPrice: gasPrice
    )
    Session.send(EthereumNodeRequest(batch: BatchFactory().create(request), nodeURL: baseURL)) { result in
      switch result {
      case .success(let value):
        let gasLimit: BigInt = {
          var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
          // Used  120% of estimated gas for safer
          limit += (limit * 20 / 100)
          if !isSwap && !data.isEmpty { // Add buffer for transfer token only
            limit += 20000
          }
          return limit
        }()
        completion(.success(gasLimit))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func requestDataForNFTTransfer(from: String, to: String, tokenID: String, amount: Int, isERC721: Bool, completion: @escaping (Result<Data, AnyError>) -> Void) {
    web3?.request(request: ContractNFTTransfer(from: from, to: to, tokenID: tokenID, amount: amount, isERC721Format: isERC721)) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getEstimateGasLimitForTransferNFT(address: String, to: String, categoryAddress: String, tokenID: String, gasPrice: BigInt, gasLimit: BigInt, amount: Int, isERC721: Bool, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.requestDataForNFTTransfer(from: address, to: to, tokenID: tokenID, amount: amount, isERC721: isERC721) { result in
      switch result {
      case .success(let data):
        self.estimateGasLimit(
          from: address,
          to: categoryAddress,
          gasPrice: gasPrice,
          value: BigInt(0),
          data: data,
          defaultGasLimit: KNGasConfiguration.transferTokenGasLimitDefault,
          isSwap: false,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getNFTBalance(address: String, id: String, contract: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    self.getNFTBalanceEncodeData(for: address, id: id) { [weak self] encodeResult in
      guard let `self` = self else { return }
      switch encodeResult {
      case .success(let data):
        let request = EthereumNodeRequest(
          batch: BatchFactory().create(CallRequest(to: contract, data: data)),
          nodeURL: self.baseURL
        )
        Session.send(request) { [weak self] result in
          guard let `self` = self else { return }
          switch result {
          case .success(let balance):
            self.getNFTBalanceDecodeData(from: balance, completion: completion)
          case .failure(let error):
            completion(.failure(AnyError(error)))
          }
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func getNFTBalanceEncodeData(for address: String, id: String, completion: @escaping (Result<String, AnyError>) -> Void) {
    let request = GetERC721BalanceEncode(address: address, id: id)
    web3?.request(request: request) { result in
      switch result {
      case .success(let data):
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  fileprivate func getNFTBalanceDecodeData(from balance: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    if balance == "0x" {
      completion(.success(BigInt(0)))
      return
    }
    let request = GetERC721BalanceDecode(data: balance)
    web3?.request(request: request) { result in
      switch result {
      case .success(let res):
        completion(.success(BigInt(res) ?? BigInt()))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getEstimateGasLimit(address: String, transferTransaction: UnconfirmedTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {

    let defaultGasLimit: BigInt = {
      KNGasConfiguration.calculateDefaultGasLimitTransfer(token: transferTransaction.transferType.tokenObject())
    }()
    self.requestDataForTokenTransfer(address: address, transaction: transferTransaction) { result in
      switch result {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: address,
          to: transferTransaction.addressToSend(),
          gasPrice: transferTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: transferTransaction.valueToSend(),
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: false,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func requestDataForTokenExchange(address: String, exchange: KNDraftExchangeTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = KNExchangeRequestEncode(exchange: exchange, address: address)
    web3?.request(request: encodeRequest) { result in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getEstimateGasLimit(transaction: SignTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let request = KNEstimateGasLimitRequest(
      from: transaction.address,
      to: transaction.to,
      value: transaction.value,
      data: transaction.data,
      gasPrice: transaction.gasPrice
    )
    let nodeRequest = EthereumNodeRequest(
      batch: BatchFactory().create(request),
      nodeURL: self.baseURL
    )
    Session.send(nodeRequest) { result in
      switch result {
      case .success(let value):
        var limit = BigInt(value.drop0x, radix: 16) ?? BigInt()
        limit += (limit * 20 / 100)
        completion(.success(limit))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getEstimateGasLimit(address: String, networkAddress: String, for exchangeTransaction: KNDraftExchangeTransaction, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
    let value: BigInt = exchangeTransaction.from.isETH ? exchangeTransaction.amount : BigInt(0)

    let defaultGasLimit: BigInt = {
      return KNGasConfiguration.calculateDefaultGasLimit(from: exchangeTransaction.from, to: exchangeTransaction.to)
    }()

    self.requestDataForTokenExchange(address: address, exchange: exchangeTransaction) { dataResult in
      switch dataResult {
      case .success(let data):
        KNExternalProvider.estimateGasLimit(
          from: address,
          to: networkAddress,
          gasPrice: exchangeTransaction.gasPrice ?? KNGasConfiguration.gasPriceDefault,
          value: value,
          data: data,
          defaultGasLimit: defaultGasLimit,
          isSwap: true,
          completion: completion
        )
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  func requestDataForTokenTransfer(address: String, transaction: UnconfirmedTransaction, completion: @escaping (Result<Data, AnyError>) -> Void) {
    web3?.request(request: ContractERC20Transfer(amount: transaction.value, address: transaction.to ?? "")) { (result) in
      switch result {
      case .success(let res):
        let data = Data(hex: res.drop0x)
        completion(.success(data))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  func getSendApproveERC20TokenEncodeData(networkAddress: String, value: BigInt = Constants.maxValueBigInt, completion: @escaping (Result<Data, AnyError>) -> Void) {
    let encodeRequest = ApproveERC20Encode(address: networkAddress, value: value)
    web3?.request(request: encodeRequest) { (encodeResult) in
      switch encodeResult {
      case .success(let data):
        completion(.success(Data(hex: data.drop0x)))
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
  
  private func valueToSend(_ transaction: UnconfirmedTransaction) -> BigInt {
    return transaction.transferType.isETHTransfer() ? transaction.value : BigInt(0)
  }

  private func addressToSend(_ transaction: UnconfirmedTransaction) -> String? {
    switch transaction.transferType {
    case .ether:
      return transaction.to
    case .token(let token):
      return token.contract
    }
  }
  
}

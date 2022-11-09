//
//  AllowanceService.swift
//  Services
//
//  Created by Com1 on 09/11/2022.
//

import Foundation
import BaseWallet
import Result
import BigInt
import JSONRPCKit
import APIKit
import AppState

public class AllowanceService: BaseService {
    
    var customRPC: CustomRPC {
        return AppState.shared.currentChain.customRPC()
    }
    
    var currentWeb3: Web3Swift = Web3Swift()
    
    var web3Swift: Web3Swift {
        if let path = URL(string: self.customRPC.endpoint) {
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
    
    public func getTokenAllowanceEncodeData(for address: String, networkAddress: String, completion: @escaping (Result<String, AnyError>) -> Void) {
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
  
    public func getTokenAllowanceDecodeData(_ data: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
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
    
    public func getAllowance(chain: ChainType, for address: String, networkAddress: String, tokenAddress: String, completion: @escaping (Result<BigInt, AnyError>) -> Void) {
        
        if tokenAddress.lowercased() == AppState.shared.currentChain.customRPC().quoteTokenAddress.lowercased() {
            completion(.success(BigInt(2).power(255)))
            return
        }
        self.getTokenAllowanceEncodeData(for: address, networkAddress: networkAddress) { [weak self] dataResult in
            switch dataResult {
            case .success(let data):
                let callRequest = CallRequest(to: tokenAddress, data: data)
                let getAllowanceRequest = EtherServiceAlchemyRequest(batch: BatchFactory().create(callRequest), chain: chain)
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
}

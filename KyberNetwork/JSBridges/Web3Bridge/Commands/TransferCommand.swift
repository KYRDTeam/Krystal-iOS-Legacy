//
//  TransferCommand.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 24/06/2022.
//

import Foundation
import KrystalJSBridge
import UIKit
import BigInt

class TransferCommand: NSObject, BridgeCommandProtocol {
  typealias BridgeInput = TransferInput
  typealias BridgeOutput = TransferOutput
  
  var eventEmitter: EventEmitter
  var commandName: String = "transfer"
  
  required init(eventEmitter: EventEmitter) {
    self.eventEmitter = eventEmitter
  }
  
  func execute(moduleName: String, subscriberId: String, params: BridgeInput) throws -> CommandSubscription? {
    guard let browser = UIApplication.getTopViewController() as? KDappBrowserViewController else {
      return nil
    }
    
    let amount: BigInt = BigInt(params.amount * pow(10, Double(ChainType.eth.quoteTokenObject().decimals)))
    let tx = UnconfirmedTransaction(transferType: .ether(destination: params.toAddress), value: amount, to: params.toAddress, data: nil, gasLimit: nil, gasPrice: nil, nonce: nil, maxInclusionFeePerGas: nil, maxGasFee: nil, estimatedFee: nil)
    
    browser.navigationController?.present(
      KConfirmSendViewController(viewModel: KConfirmSendViewModel(transaction: tx)),
      animated: true
    )
    
    sendSuccessEvent(
      to: moduleName,
      with: subscriberId,
      and: TransferOutput(code: 200, message: "Success")
    )
    
    return nil
  }
  
  struct TransferInput: Codable {
    var toAddress: String
    var amount: Double
  }
  
  struct TransferOutput: Codable {
    var code: Int
    var message: String
  }
  
}

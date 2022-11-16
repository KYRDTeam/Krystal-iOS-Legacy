//
//  TxConverter.swift
//  TransactionModule
//
//  Created by Tung Nguyen on 09/11/2022.
//

import Foundation
import Services
import AppState
import Dependencies
import BigInt
import BaseWallet

public class TxObjectConverter {
    
    let chain: ChainType
    let gasConfig: GasConfig = AppDependencies.gasConfig
    
    public init(chain: ChainType) {
        self.chain = chain
    }
    
    func getCurrentNonce(address: String) -> Int {
        return AppDependencies.nonceStorage.currentNonce(chain: chain, address: address)
    }
    
    public func convertToLegacyTransaction(txObject: TxObject, address: String, setting: TxSettingObject) -> LegacyTransaction? {
        guard let value = BigInt(txObject.value.drop0x, radix: 16),
              let gasLimitTx = BigInt(txObject.gasLimit.drop0x, radix: 16)
        else {
            return nil
        }
        let gasPrice = setting.advanced?.maxFee ?? getGasPrice(gasType: setting.basic?.gasType ?? .regular)
        let gasLimit = setting.advanced?.gasLimit ?? gasLimitTx
        let txNonce = setting.advanced?.nonce ?? getCurrentNonce(address: address)
        
        return LegacyTransaction(
            value: value,
            address: address,
            to: txObject.to,
            nonce: txNonce,
            data: Data(hex: txObject.data.drop0x),
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            chainID: chain.getChainId()
        )
    }
    
    public func convertToEIP1559Transaction(txObject: TxObject, address: String, setting: TxSettingObject) -> EIP1559Transaction? {
        guard let gasLimitTx = BigInt(txObject.gasLimit.drop0x, radix: 16)
        else {
          return nil
        }
        guard let baseFeeBigInt = gasConfig.getBaseFee(chain: chain) else { return nil }

        let txNonce = setting.advanced?.nonce ?? getCurrentNonce(address: address)
        let maxGas = setting.advanced?.maxFee ?? getGasPrice(gasType: setting.basic?.gasType ?? .regular)
        let priorityFee = setting.advanced?.maxPriorityFee ?? getPriority(gasType: setting.basic?.gasType ?? .regular)
        let gasLimit = setting.advanced?.gasLimit ?? gasLimitTx
        let chainID = BigInt(chain.getChainId()).hexEncoded
        let nonceHex = BigInt(txNonce).hexEncoded
        
        let priorityFeeBigIntDefault = maxGas - baseFeeBigInt
        return EIP1559Transaction(
          chainID: chainID.hexSigned2Complement,
          nonce: nonceHex.hexSigned2Complement,
          gasLimit: gasLimit.hexEncoded.hexSigned2Complement,
          maxInclusionFeePerGas: priorityFee?.hexEncoded.hexSigned2Complement ?? priorityFeeBigIntDefault.hexEncoded.hexSigned2Complement,
          maxGasFee: maxGas.hexEncoded.hexSigned2Complement,
          toAddress: txObject.to,
          fromAddress: txObject.from,
          data: txObject.data,
          value: txObject.value.drop0x.hexSigned2Complement,
          reservedGasLimit: gasLimit.hexEncoded.hexSigned2Complement
        )
    }
    
    func getGasPrice(gasType: GasSpeed) -> BigInt {
        let chain = AppState.shared.currentChain
        let gasConfig: GasConfig = AppDependencies.gasConfig
        switch gasType {
        case .slow:
            return gasConfig.getLowGasPrice(chain: chain)
        case .regular:
            return gasConfig.getStandardGasPrice(chain: chain)
        case .fast:
            return gasConfig.getFastGasPrice(chain: chain)
        case .superFast:
            return gasConfig.getSuperFastGasPrice(chain: chain)
        }
    }
    
    func getPriority(gasType: GasSpeed) -> BigInt? {
        switch gasType {
        case .slow:
            return gasConfig.getLowPriorityFee(chain: chain)
        case .regular:
            return gasConfig.getStandardPriorityFee(chain: chain)
        case .fast:
            return gasConfig.getFastPriorityFee(chain: chain)
        case .superFast:
            return gasConfig.getSuperFastPriorityFee(chain: chain)
        }
    }
    
    
}

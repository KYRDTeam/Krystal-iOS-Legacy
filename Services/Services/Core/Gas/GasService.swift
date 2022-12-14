//
//  GasService.swift
//  Services
//
//  Created by Tung Nguyen on 01/11/2022.
//

import Foundation
import BaseWallet
import Moya

public class GasService: BaseService {
    
    let provider = MoyaProvider<GasEndpoint>(plugins: [NetworkLoggerPlugin()])
    
    public func getGasPrice(chain: ChainType, completion: @escaping (GasPriceResponse?) -> ()) {
        provider.request(.getGasPrice(chainPath: chain.customRPC().apiChainPath)) { result in
            switch result {
            case .success(let resp):
                let response = try? JSONDecoder().decode(GasPriceResponse.self, from: resp.data)
                completion(response)
            case .failure:
                completion(nil)
            }
        }
    }
    
}

//
//  EarnServices.swift
//  KyberNetwork
//
//  Created by Com1 on 14/10/2022.
//

import Foundation
import Moya

enum EarnEndpoint {
    case listOption(chainId: String?)
    case buildStakeTx(params: JSONDictionary)
}

extension EarnEndpoint: TargetType {
    var baseURL: URL {
        return URL(string: KNEnvironment.default.krystalEndpoint + "/all")!
    }
    
    var path: String {
        switch self {
        case .listOption:
            return "/v1/earning/options"
        case .buildStakeTx:
            return "/v1/earning/buildStakeTx"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .listOption:
            return .get
        case .buildStakeTx:
            return .post
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Moya.Task {
        switch self {
        case .listOption(let chainId):
            var json: JSONDictionary = [:]
            if let chainId = chainId {
                json["chainID"] = chainId
            }
            return json.isEmpty ? .requestPlain : .requestParameters(parameters: json, encoding: URLEncoding.queryString)
        case .buildStakeTx(let params):
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        var json: [String: String] = ["client": "com.kyrd.krystal.ios"]
        return json
    }
}

class EarnServices {
    let provider = MoyaProvider<EarnEndpoint>(plugins: [NetworkLoggerPlugin(verbose: true)])
    var currentProcess: Cancellable?
    
    func getEarnListData(chainId: String?, completion: @escaping ([EarnPoolModel]) -> ()) {
        if let currentProcess = currentProcess {
            currentProcess.cancel()
        }
        self.currentProcess = provider.requestWithFilter(.listOption(chainId: chainId)) { result in
            switch result {
            case .success(let response):
                if let json = try? response.mapJSON() as? JSONDictionary ?? [:], let jsonResults = json["result"] as? [JSONDictionary] {
                    
                    var earnPools: [EarnPoolModel] = []
                    jsonResults.forEach { jsonResult in
                        earnPools.append(EarnPoolModel(json: jsonResult))
                    }
                    completion(earnPools)
                } else {
                    completion([])
                }
            case .failure:
                completion([])
            }
        } as? Cancellable
    }
}

//
//  KrystalService.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/08/2022.
//

import Foundation
import KrystalWallets
import Moya

class KrystalService {
  
  let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
  
  func sendRefCode(address: KAddress, _ code: String, completion: @escaping (_ isSuccess: Bool, _ message: String) -> ()) {
    let data = Data(code.utf8)
    let prefix = "\u{19}Ethereum Signed Message:\n\(data.count)".data(using: .utf8)!
    let sendData = prefix + data
    let signer = SignerFactory().getSigner(address: address)
    do {
      let signedData = try signer.signMessageHash(address: address, data: sendData, addPrefix: false)
      provider.requestWithFilter(.registerReferrer(address: address.addressString, referralCode: code, signature: signedData.hexEncoded)) { (result) in
        if case .success(let data) = result, let json = try? data.mapJSON() as? JSONDictionary ?? [:] {
          if let isSuccess = json["success"] as? Bool, isSuccess {
            completion(true, "Success register referral code")
          } else if let error = json["error"] as? String {
            completion(false, error)
          } else {
            completion(false, "Fail to register referral code")
          }
        }
      }
    } catch {
      print("[Send ref code] \(error.localizedDescription)")
    }
  }
  
}

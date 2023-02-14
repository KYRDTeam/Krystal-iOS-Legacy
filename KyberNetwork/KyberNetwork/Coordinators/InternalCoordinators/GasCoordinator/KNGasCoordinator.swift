// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import Result
import Moya
import JSONRPCKit
import APIKit
import BigInt
import TrustKeystore
import Utilities

class KNGasCoordinator {

  static let shared: KNGasCoordinator = KNGasCoordinator()
  fileprivate let provider = MoyaProvider<KyberNetworkService>()

  static let kSavedDefaultGas = "kSavedDefaultGas"
  static let kSavedStandardGas = "kSavedStandardGas"
  static let kSavedLowGas = "kSavedLowGas"
  static let kSavedFastGas = "kSavedFastGas"
  static let kSavedMaxGas = "kSavedMaxGas"

  lazy var numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    return formatter
  }()

  var defaultKNGas: BigInt = KNGasConfiguration.gasPriceDefault
  var standardKNGas: BigInt = KNGasConfiguration.gasPriceDefault
  var lowKNGas: BigInt = KNGasConfiguration.gasPriceMin
  var fastKNGas: BigInt = KNGasConfiguration.gasPriceMax
  var superFastKNGas: BigInt {
    if fastKNGas < EtherNumberFormatter.full.number(from: "10", units: UnitConfiguration.gasPriceUnit)! {
      return EtherNumberFormatter.full.number(from: "20", units: UnitConfiguration.gasPriceUnit)!
    }
    return fastKNGas * BigInt(2)
  }

  var defaultPriorityFee: BigInt?
  var lowPriorityFee: BigInt?
  var standardPriorityFee: BigInt?
  var fastPriorityFee: BigInt?
  var baseFee: BigInt?
  var superFastPriorityFee: BigInt? {
    if let unwrap = self.fastPriorityFee {
      return unwrap * BigInt(2)
    } else {
      return nil
    }
  }
  var estTime: EstTime?

  var maxKNGas: BigInt = KNGasConfiguration.gasPriceMax

  fileprivate var knGasPriceFetchTimer: Timer?

  init() {}

  func resume() {
    self.loadSavedGasPrice()
    knGasPriceFetchTimer?.invalidate()
    fetchKNGasPrice(nil)
    knGasPriceFetchTimer = Timer.scheduledTimer(
      timeInterval: KNLoadingInterval.seconds30,
      target: self,
      selector: #selector(fetchKNGasPrice(_:)),
      userInfo: nil,
      repeats: true
    )
  }

  func pause() {
    knGasPriceFetchTimer?.invalidate()
    knGasPriceFetchTimer = nil
  }

  fileprivate func loadSavedGasPrice() {
    if let data = Storage.retrieve(KNEnvironment.default.envPrefix + Constants.gasPriceStoreFileName, as: GasPriceResponse.self) {
      self.setGasPrice(data)
    } else {
      self.defaultKNGas = KNGasConfiguration.gasPriceDefault
      self.standardKNGas = KNGasConfiguration.gasPriceDefault
      self.lowKNGas = KNGasConfiguration.gasPriceMin
      self.fastKNGas = KNGasConfiguration.gasPriceMax
      self.defaultPriorityFee = nil
      self.lowPriorityFee = nil
      self.standardPriorityFee = nil
      self.fastPriorityFee = nil
      self.baseFee = nil
    }
  }

  @objc func fetchKNGasPrice(_ sender: Timer?) {
    DispatchQueue.global(qos: .background).async {
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))])
      provider.requestWithFilter(.getGasPriceV2) { result in
        switch result {
        case .success(let reponse):
          do {
            _ = try reponse.filterSuccessfulStatusCodes()
            let decoder = JSONDecoder()
            do {
              let data = try decoder.decode(GasPriceResponse.self, from: reponse.data)
              self.setGasPrice(data)

              Storage.store(data, as: KNEnvironment.default.envPrefix + Constants.gasPriceStoreFileName)
            } catch let error {
              print("[Debug] gas price decode error \(error)")
            }
          } catch let error {
            print("[Debug] gas price error \(error)")
          }
        default:
          break
        }
      }
    }
  }

  fileprivate func setGasPrice(_ data: GasPriceResponse) {
    self.defaultKNGas = data.gasPrice.gasPriceDefault.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.defaultKNGas
    self.lowKNGas = data.gasPrice.low.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.lowKNGas
    self.standardKNGas = data.gasPrice.standard.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.standardKNGas
    self.fastKNGas = data.gasPrice.fast.shortBigInt(units: UnitConfiguration.gasPriceUnit) ?? self.fastKNGas
    self.estTime = data.estTime
    if let priorityFee = data.priorityFee, let baseFee = data.baseFee {
      self.defaultPriorityFee = priorityFee.gasPriceDefault.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      self.lowPriorityFee = priorityFee.low.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      self.standardPriorityFee = priorityFee.standard.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      self.fastPriorityFee = priorityFee.fast.shortBigInt(units: UnitConfiguration.gasPriceUnit)
      self.baseFee = baseFee.shortBigInt(units: UnitConfiguration.gasPriceUnit)
    } else {
      self.defaultPriorityFee = nil
      self.lowPriorityFee = nil
      self.standardPriorityFee = nil
      self.fastPriorityFee = nil
      self.baseFee = nil
    }
  }
}

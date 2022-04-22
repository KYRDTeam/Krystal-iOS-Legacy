//
//  Assembler+.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 21/04/2022.
//

import Foundation
import Swinject

class DIContainer {
  
  static let assembler: Assembler = {
    let assembler = Assembler([
      ViewModelAssembly(),
      ViewControllerAssembly()
    ], container: Container())
    return assembler
  }()
  
  static func resolve<T>(_ serviceType: T.Type) -> T? {
    return assembler.resolver.resolve(serviceType)
  }
  
  static func resolve<T, Arg>(_ serviceType: T.Type, argument: Arg) -> T? {
    return assembler.resolver.resolve(serviceType, argument: argument)
  }
  
  static func resolve<T, Arg1, Arg2>(_ serviceType: T.Type, arguments arg1: Arg1, _ arg2: Arg2) -> T? {
    return assembler.resolver.resolve(serviceType, arguments: arg1, arg2)
  }
  
  static func resolve<T, Arg1, Arg2, Arg3>(_ serviceType: T.Type, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> T? {
    return assembler.resolver.resolve(serviceType, arguments: arg1, arg2, arg3)
  }
  
  static func resolve<T, Arg1, Arg2, Arg3, Arg4>(_ serviceType: T.Type, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) -> T? {
    return assembler.resolver.resolve(serviceType, arguments: arg1, arg2, arg3, arg4)
  }
  
}

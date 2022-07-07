//
//  ViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 06/07/2022.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModelType {
  associatedtype Input
  associatedtype Output
  
  func transform(input: Input) -> Output
}

class ViewModel: NSObject {
  let loading = ActivityIndicator()
  let headerLoading = ActivityIndicator()
  let footerLoading = ActivityIndicator()
  
  let error = ErrorTracker()
}

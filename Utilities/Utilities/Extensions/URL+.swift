//
//  URL+.swift
//  Utilities
//
//  Created by Tung Nguyen on 22/11/2022.
//

import Foundation

public extension URL {
  
  func appending(_ queryItem: String, value: String?) -> URL {
    guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
    var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
    let queryItem = URLQueryItem(name: queryItem, value: value)
    queryItems.append(queryItem)
    urlComponents.queryItems = queryItems
    return urlComponents.url!
  }
  
}

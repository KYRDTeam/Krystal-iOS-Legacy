// Copyright SIX DAY LLC. All rights reserved.

extension Array where Element: Equatable {
  var unique: [Element] {
    var uniqueValues = [Element]()
    forEach { element in
      if !uniqueValues.contains(element) {
        uniqueValues.append(element)
      }
    }
    return uniqueValues
  }
}

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
  
  public subscript(safeIndex index: Int) -> Element? {
    guard index >= 0, index < endIndex else {
      return nil
    }
    
    return self[index]
  }
}

extension Array where Element: Equatable {
  func containsElementsOf(other: Array) -> Bool {
    return self.contains(where: { element in other.contains(element) })
  }
}

extension Array {
  var isNotEmpty: Bool {
    return !isEmpty
  }
}

extension Array where Element: Equatable {
    mutating func move(_ item: Element, to newIndex: Index) {
        if let index = index(of: item) {
            move(at: index, to: newIndex)
        }
    }

    mutating func bringToFront(item: Element) {
        move(item, to: 0)
    }

    mutating func sendToBack(item: Element) {
        move(item, to: endIndex-1)
    }
}

extension Array {
    mutating func move(at index: Index, to newIndex: Index) {
        insert(remove(at: index), at: newIndex)
    }
}

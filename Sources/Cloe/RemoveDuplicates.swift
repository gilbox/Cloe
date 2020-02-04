// Created by Gil Birman on 1/27/20.

import Combine
import Foundation

extension Publisher {
  public func removeDuplicates<Value: Equatable>(_ keyPath: KeyPath<Output, Value>) -> Publishers.RemoveDuplicates<Self> {
    removeDuplicates { $0[keyPath: keyPath] == $1[keyPath: keyPath] }
  }

  public func removeDuplicates<Value: Equatable, Value2: Equatable>(
    _ keyPath: KeyPath<Output, Value>,
    _ keyPath2: KeyPath<Output, Value2>)
    -> Publishers.RemoveDuplicates<Self>
  {
    removeDuplicates {
      $0[keyPath: keyPath] == $1[keyPath: keyPath] &&
      $0[keyPath: keyPath2] == $1[keyPath: keyPath2]
    }
  }

  public func removeDuplicates<Value: Equatable, Value2: Equatable, Value3: Equatable>(
    _ keyPath: KeyPath<Output, Value>,
    _ keyPath2: KeyPath<Output, Value2>,
    _ keyPath3: KeyPath<Output, Value3>)
    -> Publishers.RemoveDuplicates<Self>
  {
    removeDuplicates {
      $0[keyPath: keyPath] == $1[keyPath: keyPath] &&
      $0[keyPath: keyPath2] == $1[keyPath: keyPath2] &&
      $0[keyPath: keyPath3] == $1[keyPath: keyPath3]
    }
  }
}

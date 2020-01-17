// Created by Gil Birman on 1/16/20.

import Foundation

final class Box<T> {
  public var value: T
  public init(_ value: T) {
    self.value = value
  }
}

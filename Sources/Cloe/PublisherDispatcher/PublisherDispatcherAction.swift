// Created by Gil Birman on 1/20/20.

import Foundation

public struct PublisherDispatcherAction<State>: Action {
  public let update: (inout State) -> Void
}

public struct PublisherDispatcher {
  static public func reducer<State>(state: inout State, action: Action) {
    guard
      let action = action as? PublisherDispatcherAction<State>
      else { return }

    action.update(&state)
  }
}

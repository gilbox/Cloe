// Created by Gil Birman on 1/20/20.

import Foundation

public struct PublisherDispatcherAction<State>: Action {
  // NOTE: .finished is substituted for both .completed and .completedWithOutput actions
  // because currently we don't have a good way of differentiating between the two
  public enum Event: String {
    case initial
    case loading
    case loadingWithOutput
    case finished
    case failed
    case cancelled
  }

  public let event: Event
  public let debugDescription: String?
  public let update: (inout State) -> Void

  /// Create an action with a payload that performs a state transformation
  /// - Parameter event: The type of update being performed. You can use this for
  ///   observing the state change, it is ignored by `publisherDispatcherReducer`.
  /// - Parameter description: Description of this action for debugging/logging
  /// - Parameter update: Closure that performs an update. Invoked in the reducer.
  public init(_ event: Event, description: String?, _ update: @escaping (inout State) -> Void) {
    self.event = event
    debugDescription = description
    self.update = update
  }
}

extension PublisherDispatcherAction: CustomStringConvertible {
  public var description: String {
    "[PublisherDispatcherAction<\(type(of: State.self))>] \(debugDescription ?? "") event:\(event.rawValue)"
  }
}

public func publisherDispatcherReducer<State>(state: inout State, action: Action) {
  (action as? PublisherDispatcherAction<State>)?.update(&state)
}

// Created by Gil Birman on 1/11/20.

import Combine

/// Just like a thunk, except that you also return an AnyCancellable
/// reference and Cloe will hold on to it for you while your Combine
/// pipeline processes an async task.
@available(iOS 13.0, *)
public class PublisherAction<State>: Action {

  // MARK: Public

  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping () -> State?)
    -> AnyCancellable

  public init(body: @escaping Body) {
    self.body = body
  }

  // MARK: Internal

  let body: Body
  var cancellables = Set<AnyCancellable>()
}

@available(iOS 13.0, *)
public func createPublisherMiddleware<State>() -> Middleware<State> {
  { (fullDispatch, getState, nextDispatch) in
    { action in
      switch action {
      case let publisherAction as PublisherAction<State>:
        publisherAction
          .body(fullDispatch, getState)
          .store(in: &publisherAction.cancellables)
      default:
        nextDispatch(action)
      }
    }
  }
}

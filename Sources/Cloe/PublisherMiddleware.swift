// Created by Gil Birman on 1/11/20.

import Combine

/// Similar to a thunk, except that it will hold on to a Set of
/// AnyCancellable instances while your Combine pipelines process an async task.
@available(iOS 13.0, *)
public class PublisherAction<State>: Action {

  // MARK: Public

  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping () -> State?,
    _ cancellables: inout Set<AnyCancellable>)
    -> Void

  /// Instantiates an async action that retains Combine cancel objects.
  /// - Parameter body: Function that is executed when this action
  ///    is dispatched.
  /// - Parameter body.dispatch: Dispatch an action.
  /// - Parameter body.getState: Get state of the store.
  /// - Parameter body.cancellables: Set of cancellables retained by this PublisherAction instance.
  public init(_ body: @escaping Body) {
    self.body = body
  }

  // MARK: Internal

  let body: Body?

  func execute(dispatch: @escaping Dispatch, getState: @escaping () -> State?) {
    body?(dispatch, getState, &cancellables)
  }

  // MARK: Private

  private var cancellables = Set<AnyCancellable>()
}

@available(iOS 13.0, *)
public func createPublisherMiddleware<State>() -> Middleware<State> {
  { (fullDispatch, getState, nextDispatch) in
    { action in
      switch action {
      case let publisherAction as PublisherAction<State>:
        publisherAction.execute(dispatch: fullDispatch, getState: getState)
      default:
        nextDispatch(action)
      }
    }
  }
}

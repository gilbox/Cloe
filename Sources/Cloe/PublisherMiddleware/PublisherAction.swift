// Created by Gil Birman on 1/11/20.

import Combine
import Foundation

/// Similar to a thunk, except that it will hold on to a Set of
/// AnyCancellable instances while your Combine pipelines process an async task.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public final class PublisherAction<State>: Action {

  // MARK: Public

  public typealias GetState = () -> State?
  public typealias Cancellables = Set<AnyCancellable>
  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping GetState,
    _ cancellables: inout Cancellables)
    -> Void

  /// Context makes it a bit easier to use code-completion
  /// with a PublisherAction's alternate initializer
  public final class Context {
    public let dispatch: Dispatch
    public let getState: GetState
    public var cancellables = Cancellables()

    init(
      _ dispatch: @escaping Dispatch,
      _ getState: @escaping GetState)
    {
      self.dispatch = dispatch
      self.getState = getState
    }
  }

  /// Instantiates an async action that retains Combine cancel objects.
  /// - Parameter body: Function that is executed when this action
  ///    is dispatched.
  /// - Parameter body.dispatch: Dispatch an action.
  /// - Parameter body.getState: Get state of the store.
  /// - Parameter body.cancellables: Set of cancellables retained by this PublisherAction instance.
  public init(body: @escaping Body) {
    self.body = body
  }

  /// Instantiates an async action that retains Combine cancel objects.
  /// - Parameter body: A Context object.
  public init(_ body: @escaping (Context) -> Void) {
    self.body = { dispatch, getState, cancellable in
      let context = Context(dispatch, getState)
      body(context)
      cancellables = context.cancellables
    }
  }

  // MARK: Internal

  func execute(
    dispatch: @escaping Dispatch,
    getState: @escaping GetState)
    -> Set<AnyCancellable>
  {
    body(dispatch, getState, &cancellables)
  }

  // MARK: Private

  private let body: Body
  private var cancellables = Cancellables()
}

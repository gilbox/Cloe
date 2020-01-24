// Created by Gil Birman on 1/11/20.

import Combine
import Foundation

/// Similar to a thunk, except that it will retain a `Set` of
/// `AnyCancellable` instances while your Combine pipelines process an async task.
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

  /// Instantiates an async action that retains Combine cancel objects.
  ///
  ///     PublisherAction<MyState> { dispatch, getState, cancellables in
  ///         myPublisher1
  ///           ...
  ///           .tap { ... }
  ///           .store(in: &cancellables)
  ///         myPublisher2
  ///           ...
  ///           .tap { ... }
  ///           .store(in: &cancellables)
  ///         ...
  ///       }
  ///
  /// `body` function arguments:
  /// - `dispatch`: Dispatch an action.
  /// - `getState`: Get state of the store.
  /// - `cancellables`: Set of cancellables retained by this PublisherAction instance.
  ///
  /// - Parameter description: Description of this action for debugging/logging
  /// - Parameter body: Function that is executed when this action is dispatched.
  public init(description: String? = nil, body: @escaping Body) {
    debugDescription = description
    self.body = body
  }

  // MARK: Internal

  func execute(
    dispatch: @escaping Dispatch,
    getState: @escaping GetState)
  {
    body(dispatch, getState, &cancellables)
  }

  // MARK: Private

  private let debugDescription: String?
  private let body: Body!
  private var cancellables = Cancellables()
}

extension PublisherAction: CustomStringConvertible {
  public var description: String {
    "[PublisherAction<\(type(of: State.self))>] \(debugDescription ?? "") (\(cancellables.count) cancellables)"
  }
}

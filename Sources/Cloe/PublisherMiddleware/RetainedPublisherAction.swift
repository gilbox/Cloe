// Created by Gil Birman on 1/15/20.

import Combine
import Foundation

extension Publisher {
  /// Calls the provided cleanup function when the pipeline is cancelled or completes.
  /// A sink operator placed after this handleCleanup will still fire even if the cleanup function
  /// zeros out the references for the pipeline, so long as there are no async
  /// operations after handleCleanup.
  public func handleCleanup(_ cleanup: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
    var complete = false
    return handleEvents(
      receiveCompletion: { _ in
        if complete { return }
        complete = true
        cleanup()
      },
      receiveCancel: {
        if complete { return }
        complete = true
        cleanup()
      })
  }
}

/// Similar to a thunk, except that the middleware will retain your
/// AnyCancellable instances while your Combine pipelines process an async task.
///
/// `RetainedPublisherAction` is different from `PublisherAction` because with `PublisherAction`,
/// your cancellables are retained by the `PublisherAction` instance, and
/// when you de-allocate that instance, the cancellables
/// are de-referenced and the Combine pipelines cancelled.
/// In `RetainedPublisherAction`, the cancellables are retained in the
/// `createPublisherMiddleware` inner closure, thus the cancellables are
/// retained until one of the following two events:
///  - The cleanup() function is called as many times as the number of cancellables
///  - or the store is deallocated
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public final class RetainedPublisherAction<State>: Action {

  // MARK: Public

  public typealias GetState = () -> State?
  public typealias Cancellables = Set<AnyCancellable>
  public typealias Cleanup = () -> Void
  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping GetState,
    _ cancellables: inout Cancellables,
    _ cleanup: @escaping Cleanup)
    -> Void

  /// Instantiates an async action that retains Combine AnyCancellable objects.
  ///
  ///     RetainedPublisherAction<MyState> { dispatch, getState, cancellables, cleanup in
  ///        myPublisher1
  ///          ...
  ///          .handleCleanup(cleanup)
  ///          .tap { ... }   // <-- handleCleanup and store sandwich the subscriber that returns AnyCancellable
  ///          .store(in: &cancellables)
  ///        myPublisher2
  ///          ...
  ///          .handleCleanup(cleanup)
  ///          .tap { ... }
  ///          .store(in: &cancellables)
  ///        ...
  ///      }
  ///
  /// body function arguments:
  /// - `dispatch`: Dispatch an action to the store.
  /// - `getState`: Get state of the store.
  /// - `cancellables`: `Set` of `AnyCancellable` retained by the `createPublisherMiddleware` inner closure.
  /// - `cleanup`: After this function is called once for every cancellable, the middleware releases this `RetainedPublisherAction` instance
  ///
  /// - Parameter description: Description of this action for debugging/logging
  /// - Parameter body: Function that is executed when this action is dispatched.
  ///
  public init(description: String? = nil, body: @escaping Body) {
    debugDescription = description
    self.body = body
  }

  // MARK: Internal

  func execute(
    dispatch: @escaping Dispatch,
    getState: @escaping GetState,
    cleanup: @escaping Cleanup)
    -> Set<AnyCancellable>
  {
    var cancellables = Set<AnyCancellable>()
    body(dispatch, getState, &cancellables, cleanup)
    return cancellables
  }

  // MARK: Private

  private let debugDescription: String?
  private let body: Body
}

extension RetainedPublisherAction: CustomStringConvertible {
  public var description: String {
    "[RetainedPublisherAction<\(type(of: State.self))>] \(debugDescription ?? "")"
  }
}

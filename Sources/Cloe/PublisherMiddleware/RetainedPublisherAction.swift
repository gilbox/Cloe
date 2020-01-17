// Created by Gil Birman on 1/15/20.

import Combine
import Foundation

private final class Box<T> {
  public var value: T
  public init(_ value: T) {
    self.value = value
  }
}

extension Publisher {
  /// Calls the provided cleanup function when the pipeline is cancelled or completes.
  /// A sink operator placed after this handleCleanup will still fire even if the cleanup function
  /// zeros out the references for the pipeline, so long as there are no async
  /// operations after handleCleanup.
  public func handleCleanup(_ cleanup: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
    let complete = Box(false)
    return handleEvents(
      receiveCompletion: { _ in
        if complete.value { return }
        complete.value = true
        cleanup()
      },
      receiveCancel: {
        if complete.value { return }
        complete.value = true
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

  /// Context makes it a bit easier to use code-completion
  /// with a PublisherAction's alternate initializer
  public final class Context {
    public let dispatch: Dispatch
    public let getState: GetState
    public var cancellables = Cancellables()
    public let cleanup: Cleanup

    init(
      _ dispatch: @escaping Dispatch,
      _ getState: @escaping GetState,
      _ cleanup: @escaping Cleanup)
    {
      self.dispatch = dispatch
      self.getState = getState
      self.cleanup = cleanup
    }
  }

  /// Instantiates an async action that retains Combine AnyCancellable objects.
  ///
  ///     RetainedPublisherAction<MyState> { dispatch, getState, cancellables, cleanup in
  ///        myPublisher1
  ///          ...
  ///          .handleCleanup(cleanup)
  ///          .tap { ... }   // <-- handleCleanup and store sandwhich the subscriber that returns AnyCancellable
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
  /// - Parameter body: Function that is executed when this action is dispatched.
  ///
  public init(body: @escaping Body) {
    self.body = body
  }

  /// Instantiates an async action that retains Combine cancel objects.
  ///
  ///      RetainedPublisherAction<MyState> { context in
  ///         myPublisher1
  ///           ...
  ///           .handleCleanup(context.cleanup)
  ///           .tap { ... }   // <-- handleCleanup and store sandwhich the subscriber that returns AnyCancellable
  ///           .store(in: &context.cancellables)
  ///         myPublisher2
  ///           ...
  ///           .handleCleanup(context.cleanup)
  ///           .tap { ... }
  ///           .store(in: &context.cancellables)
  ///         ...
  ///       }
  ///
  /// - Parameter body: Function that is executed when this action is dispatched.
  public init(_ body: @escaping (Context) -> Void) {
    self.body = { dispatch, getState, cancellables, cleanup in
      let context = Context(dispatch, getState, cleanup)
      body(context)
      cancellables = context.cancellables
    }
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

  private let body: Body
}

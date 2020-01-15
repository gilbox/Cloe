// Created by Gil Birman on 1/11/20.

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

/// Similar to a thunk, except that it will hold on to a Set of
/// AnyCancellable instances while your Combine pipelines process an async task.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public final class PublisherAction<State>: Action {

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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public func createPublisherMiddleware<State>() -> Middleware<State> {
  var cancellablesCache = [UUID:Set<AnyCancellable>]()

  return { (fullDispatch, getState, nextDispatch) in
    { action in
      switch action {
      case let publisherAction as PublisherAction<State>:
        let refCount = Box(0)
        let uuid = UUID()
        let cleanup = {
          refCount.value -= 1
          if refCount.value == 0 {
            cancellablesCache[uuid] = nil
          }
          // Note: Negative ref count can happen for 2 reasons:
          // 1. cleanup() was called too many times
          // 2. the publisher is syncronous and calls cleanup before ref count is updated below
        }
        let cancellables = publisherAction.execute(
          dispatch: fullDispatch,
          getState: getState,
          cleanup: cleanup)
        if cancellables.count > 0 {
          refCount.value = cancellables.count
          cancellablesCache[uuid] = cancellables
        }
      default:
        nextDispatch(action)
      }
    }
  }
}

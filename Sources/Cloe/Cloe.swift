// Created by Gil Birman on 1/11/20.

import Combine
import SwiftUI

public typealias StateSelector<State, SubState> = (State) -> SubState

public protocol Action {}

public typealias Dispatch = (Action) -> Void

/// A container for the `reduce` function which returns a new store state
/// given the current store state and an action. Should not contain
/// async logic, only pure functions. Async tasks should be handled with
/// Thunk or PublisherAction or some other special middleware-provided
/// action.
public typealias Reducer<State> = (_ state: inout State, _ action: Action) -> Void

/// Combine multiple reducers into one
public func combinedReducers<State>(_ reducers: Reducer<State>...) -> Reducer<State> {
  { (state: inout State, action: Action) in
    for reducer in reducers {
      reducer(&state, action)
    }
  }
}

/// A way to plugin to the Store's dispatch function
/// - Parameter fullDispatch: Dispatch an action
/// - Parameter getState: Call to get the current state of the Store
/// - Parameter nextDispatch: Dispatch an action using the next middleware
public typealias Middleware<State> = (
  _ fullDispatch: @escaping Dispatch,
  _ getState: @escaping () -> State?,
  _ nextDispatch: @escaping Dispatch)
  -> Dispatch

/// A Cloe Store
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public class Store<State>: ObservableObject {

  // MARK: Public

  public typealias StoreMiddleware = Middleware<State>

  /// Create a Store
  /// - Parameter reducer: Reducer for your store
  /// - Parameter state: Initial state of the store
  /// - Parameter middlewares: An array of middleware
  public init(reducer: @escaping Reducer<State>, state: State, middlewares: [StoreMiddleware]) {
    _statePublisher = CurrentValueSubject(state)
    statePublisher = _statePublisher.eraseToAnyPublisher()

    self.reducer = reducer
    self.middlewares = middlewares
    self.dispatchFunction = composeMiddlewares(middlewares)
  }

  /// Publishes the current state of the store
  public let statePublisher: AnyPublisher<State, Never>

  public var middlewares: [StoreMiddleware] {
    didSet {
      self.dispatchFunction = composeMiddlewares(middlewares)
    }
  }

  /// Current state of the store
  public var state: State {
    _statePublisher.value
  }

  /// Dispatch an action
  public func dispatch(_ action: Action) {
    dispatchFunction(action)
  }

  public subscript(_ action: Action) -> (() -> Void) {
    { [weak self] in self?.dispatch(action) }
  }

  /// Returns a publisher for the given derived state selector.
  /// Removes repeated states.
  /// - Parameter selector: A function that returns a derived state
  ///     given the store's current state as input.
  public func uniqueSubStatePublisher<SubState: Equatable>(
    _ selector: @escaping StateSelector<State, SubState>)
    -> AnyPublisher<SubState, Never>
  {
    _statePublisher
      .map(selector)
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  /// Returns a publisher for the given derived state selector.
  /// Does not remove repeated states.
  /// - Parameter selector: A function that returns a derived state
  ///     given the store's current state as input.
  public func subStatePublisher<SubState>(
    _ selector: @escaping StateSelector<State, SubState>)
    -> AnyPublisher<SubState, Never>
  {
    _statePublisher
      .map(selector)
      .eraseToAnyPublisher()
  }

  // MARK: Private

  private typealias GetState = () -> State?
  private let _statePublisher: CurrentValueSubject<State, Never>
  private let reducer: Reducer<State>
  private var cancellables = [AnyCancellable]()
  private lazy var dispatchFunction: Dispatch = {
    [weak self] in self?.defaultDispatch(action: $0)
  }

  private func composeMiddlewares(_ middlewares: [StoreMiddleware]) -> Dispatch {
    let getState: GetState = { [weak self] in self?._statePublisher.value }
    let initialDispatch: Dispatch = { [weak self] in self?.defaultDispatch(action: $0) }
    let fullDispatch: Dispatch = { [weak self] in self?.dispatchFunction($0) }

    return middlewares.reversed()
      .reduce(initialDispatch) { nextDispatch, middleware in
        middleware(fullDispatch, getState, nextDispatch)
      }
  }

  private func defaultDispatch(action: Action) {
    var state = _statePublisher.value
    reducer(&state, action)
    _statePublisher.send(state)
  }
}

// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

<<<<<<< Updated upstream
/// Track the state of a Combine Publisher
public enum PublisherState<Output, Failure: Error> {
  case initial
  case loading
  case loadingWithOutput(_ value: Output)
  case completed
  case completedWithOutput(_ value: Output)
  case failed(_ error: Failure)
  case cancelled
=======
public final class PublisherState<Output> {

  // MARK: Public

  public enum Status: Equatable {
    case initial
    case loading
    case completed
    case failed
    case cancelled
  }

  public enum Event {
    case reset
    case loading
    case output(_ value: Output)
    case completed
    case failed(_ error: Error)
    case cancelled
  }

  public init(status: Status) {
    self.status = status
  }

  public static var initial: PublisherState<Output> { .init(status: .initial) }

  public private(set) var status: Status

  public private(set) var error: Error? {
    get { _error?.value }
    set { _error = newValue.map { Ref($0) } }
  }

  public private(set) var output: Output? {
    get { _output?.value }
    set { _output = newValue.map { Ref($0) } }
  }

  public func update(_ event: Event) {
    switch event {
    case .reset:
      status = .initial
      error = nil
      output = nil
    case .loading:
      status = .loading
      error = nil
      output = nil
    case .output(let value):
      status = .loading
      output = value
    case .completed:
      status = .completed
    case .failed(let error):
      status = .failed
      self.error = error
    case .cancelled:
      status = .cancelled
    }
  }

  // MARK: Private

  private var _error: Ref<Error>? = nil
  private var _output: Ref<Output>? = nil
>>>>>>> Stashed changes
}

extension PublisherState {
  public var isLoading: Bool {
    status == .loading
  }

  public var isCompleted: Bool {
    status == .completed
  }

  public var isDone: Bool {
    switch status {
    case .cancelled, .completed, .failed:
      return true
    default:
      return false
    }
  }
}

<<<<<<< Updated upstream
extension PublisherState: Equatable where Output: Equatable {
  public static func == (lhs: PublisherState, rhs: PublisherState) -> Bool {
    switch (lhs, rhs) {
    case (.initial, .initial),
         (.loading, .loading),
         (.completed, .completed),
         (.cancelled, .cancelled),
          // Since a Publisher can only fail once and it must
          // enter a different state before failing, this should
          // be the correct assumption for the failed case so long as
          // we don't do anything weird with PublisherStatus
         (.failed(_), .failed(_)):
      return true
    case (.loadingWithOutput(let a), .loadingWithOutput(let b)),
         (.completedWithOutput(let a), .completedWithOutput(let b)):
      return a == b
    default:
      return false
    }
=======
extension PublisherState: Equatable {
  public static func == (lhs: PublisherState<Output>, rhs: PublisherState<Output>) -> Bool {
    lhs.status == rhs.status
      && lhs._error === rhs._error
      && lhs._output === rhs._output
  }
}

extension PublisherState {
  /// An instance and it's copy are equal because
  /// error and output references are the same
  public func copy() -> PublisherState {
    let clone = PublisherState(status: status)
    clone._error = _error
    clone._output = _output
    return clone
>>>>>>> Stashed changes
  }
}

extension Publisher {
  /// Automatically dispatches actions on your behalf to update the
  /// state of a `PublisherState` object in your store.
  ///
  /// The dispatched actions are not intended to be used in any way
  /// that isn't already supported by the PublisherDispatcher reducer.
  public func stateDispatcher<State>(
    _ dispatch: @escaping Dispatch,
    statePath: WritableKeyPath<State, PublisherState<Output, Failure>>,
    description: String? = nil)
    -> Publishers.HandleEvents<Self>
  {
    var fullDescription = "[StateDispatcher]"
    if let description = description {
      fullDescription += " \(description)"
    }
    return handleEvents(
      receiveOutput: { value in
<<<<<<< Updated upstream
        dispatch(PublisherDispatcherAction<State>(.loadingWithOutput, description: fullDescription) { state in
          state[keyPath: statePath] = .loadingWithOutput(value)
=======
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath].update(.output(value))
>>>>>>> Stashed changes
        })
      },
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
<<<<<<< Updated upstream
          dispatch(PublisherDispatcherAction<State>(.failed, description: fullDescription) { state in
            state[keyPath: statePath] = .failed(error)
          })
        case .finished:
          dispatch(PublisherDispatcherAction<State>(.finished, description: fullDescription) { state in
            if case .loadingWithOutput(let value) = state[keyPath: statePath] {
              state[keyPath: statePath] = .completedWithOutput(value)
            } else {
              state[keyPath: statePath] = .completed
            }
=======
          dispatch(PublisherDispatcherAction<State> { state in
            state[keyPath: statePath].update(.failed(error))
          })
        case .finished:
          dispatch(PublisherDispatcherAction<State> { state in
            state[keyPath: statePath].update(.completed)
>>>>>>> Stashed changes
          })
        }
      },
      receiveCancel: {
<<<<<<< Updated upstream
        dispatch(PublisherDispatcherAction<State>(.cancelled, description: fullDescription) { state in
          state[keyPath: statePath] = .cancelled
        })
      },
      receiveRequest: { _ in
        dispatch(PublisherDispatcherAction<State>(.loading, description: fullDescription) { state in
          state[keyPath: statePath] = .loading
=======
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath].update(.cancelled)
        })
      },
      receiveRequest: { demand in
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath].update(.loading)
>>>>>>> Stashed changes
        })
      })
  }
}

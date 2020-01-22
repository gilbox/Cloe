// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

/// Track the state of a Combine Publisher
public enum PublisherState<Output, Failure: Error> {
  case initial
  case loading
  case loadingWithOutput(_ value: Output)
  case completed
  case completedWithOutput(_ value: Output)
  case failed(_ error: Failure)
  case cancelled
}

extension PublisherState {
  public var isLoading: Bool {
    switch self {
    case .loading, .loadingWithOutput(_):
      return true
    default:
      return false
    }
  }

  public var isCompleted: Bool {
    switch self {
    case .completed, .completedWithOutput(_):
      return true
    default:
      return false
    }
  }

  public var isDone: Bool {
    switch self {
    case .cancelled, .completedWithOutput(_), .completed, .failed(_):
      return true
    default:
      return false
    }
  }
}

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
    statePath: WritableKeyPath<State, PublisherState<Output, Failure>>)
    -> Publishers.HandleEvents<Self>
  {
    handleEvents(
      receiveOutput: { value in
        dispatch(PublisherDispatcherAction<State>(.loadingWithOutput) { state in
          state[keyPath: statePath] = .loadingWithOutput(value)
        })
      },
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          dispatch(PublisherDispatcherAction<State>(.failed) { state in
            state[keyPath: statePath] = .failed(error)
          })
        case .finished:
          dispatch(PublisherDispatcherAction<State>(.finished) { state in
            if case .loadingWithOutput(let value) = state[keyPath: statePath] {
              state[keyPath: statePath] = .completedWithOutput(value)
            } else {
              state[keyPath: statePath] = .completed
            }
          })
        }
      },
      receiveCancel: {
        dispatch(PublisherDispatcherAction<State>(.cancelled) { state in
          state[keyPath: statePath] = .cancelled
        })
      },
      receiveRequest: { _ in
        dispatch(PublisherDispatcherAction<State>(.loading) { state in
          state[keyPath: statePath] = .loading
        })
      })
  }
}

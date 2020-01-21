// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

public enum PublisherState<Output> {
  case initial
  case loading
  case loadingWithOutput(_ value: Output)
  case completed
  case completedWithOutput(_ value: Output)
  case failed(_ error: Error)
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

extension Publisher {
  public func stateDispatcher<State>(
    _ dispatch: @escaping Dispatch,
    statePath: WritableKeyPath<State, PublisherState<Output>>)
    -> Publishers.HandleEvents<Self>
  {
    handleEvents(
      receiveOutput: { value in
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath] = .loadingWithOutput(value)
        })
      },
      receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          dispatch(PublisherDispatcherAction<State> { state in
            state[keyPath: statePath] = .failed(error)
          })
        case .finished:
          dispatch(PublisherDispatcherAction<State> { state in
            if case .loadingWithOutput(let value) = state[keyPath: statePath] {
              state[keyPath: statePath] = .completedWithOutput(value)
            } else {
              state[keyPath: statePath] = .completed
            }
          })
        }
      },
      receiveCancel: {
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath] = .cancelled
        })
      },
      receiveRequest: { demand in
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath] = .loading
        })
      })
  }
}

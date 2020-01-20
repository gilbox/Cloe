// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

public enum PublisherState<Output> {
  case initial
  case loading
  case active(_ value: Output)
  case failed(_ error: Error)
  case completed
  case completedWithOutput(_ value: Output)
  case cancelled

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
          state[keyPath: statePath] = .active(value)
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
            if case .active(let value) = state[keyPath: statePath], State.self != Void.self {
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

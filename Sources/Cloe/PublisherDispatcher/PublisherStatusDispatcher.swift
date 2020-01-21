// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

public enum PublisherStatus {
  case initial
  case loading
  case loadingWithOutput
  case completed
  case completedWithOutput
  case failed(_ error: Error)
  case cancelled

  public var isLoading: Bool {
    switch self {
    case .loading, .loadingWithOutput:
      return true
    default:
      return false
    }
  }

  public var isDone: Bool {
    switch self {
    case .cancelled, .completed, .completedWithOutput, .failed(_):
      return true
    default:
      return false
    }
  }
}

extension Publisher {
  public func statusDispatcher<State>(
    _ dispatch: @escaping Dispatch,
    statePath: WritableKeyPath<State, PublisherStatus>)
    -> Publishers.HandleEvents<Self>
  {
    handleEvents(
      receiveOutput: { _ in
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath] = .loadingWithOutput
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
            if case .loadingWithOutput = state[keyPath: statePath] {
              state[keyPath: statePath] = .completedWithOutput
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

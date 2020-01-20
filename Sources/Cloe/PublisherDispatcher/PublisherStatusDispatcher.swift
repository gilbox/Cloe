// Created by Gil Birman on 1/19/20.

import Combine
import Foundation

public enum PublisherStatus {
  case initial
  case loading
  case active
  case failed(_ error: Error)
  case completed
  case cancelled

  public var isDone: Bool {
    switch self {
    case .cancelled, .completed, .failed(_):
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
      receiveOutput: { value in
        dispatch(PublisherDispatcherAction<State> { state in
          state[keyPath: statePath] = .active
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
            state[keyPath: statePath] = .completed
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

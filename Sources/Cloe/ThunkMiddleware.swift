// Created by Gil Birman on 1/11/20.

/// The classic Thunk middleware.
public struct Thunk<State>: Action {

  // MARK: Public

  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping () -> State?)
    -> Void

  public init(body: @escaping Body) {
    self.body = body
  }

  // MARK: Internal

  let body: Body
}

public func createThunkMiddleware<State>() -> Middleware<State> {
  { (fullDispatch, getState, nextDispatch) in
    { action in
      switch action {
      case let thunk as Thunk<State>:
        thunk.body(fullDispatch, getState)
      default:
        nextDispatch(action)
      }
    }
  }
}

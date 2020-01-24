// Created by Gil Birman on 1/11/20.

/// The classic Thunk middleware.
public struct Thunk<State>: Action {

  // MARK: Public

  public typealias Body = (
    _ dispatch: @escaping Dispatch,
    _ getState: @escaping () -> State?)
    -> Void

  public init(description: String? = nil, body: @escaping Body) {
    debugDescription = description
    self.body = body
  }

  // MARK: Internal

  let body: Body

  // MARK: Private

  private let debugDescription: String?
}

extension Thunk: CustomStringConvertible {
  public var description: String {
    "[Thunk<\(type(of: State.self))>] \(debugDescription ?? "")"
  }
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

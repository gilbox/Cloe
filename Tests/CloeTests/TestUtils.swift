// Created by Gil Birman on 1/18/20.

import Foundation
import Combine
@testable import Cloe

func asyncPublisher() -> AnyPublisher<Int, Never> {
  let p = PassthroughSubject<Int, Never>()
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak p] in
    p?.send(1)
    p?.send(completion: .finished)
  }
  return p.eraseToAnyPublisher()
}

enum MyError: Error { case fail }
func asyncErrorPublisher() -> AnyPublisher<Int, MyError> {
  let p = PassthroughSubject<Int, MyError>()
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak p] in
    p?.send(1)
    p?.send(completion: .failure(MyError.fail))
  }
  return p.eraseToAnyPublisher()
}

struct AppState {
  var name: String = "Initial"
  var age = 5
}

enum AppAction: Action {
  case changeName
}

func appReducer(state: inout AppState, action: Action) {
  switch action {
  case AppAction.changeName:
    state.name = "Changed Name"
  default:
    break
  }
}

typealias AppStore = Store<AppState>

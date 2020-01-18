// Created by Gil Birman on 1/18/20.

import Foundation
import Combine
@testable import Cloe

func asyncPublisher() -> AnyPublisher<Int, Never> {
  let p = PassthroughSubject<Int, Never>()
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak p] in
    p?.send(1)
  }
  return p.eraseToAnyPublisher()
}

struct AppState {
  var name: String = "Initial"
}

enum AppAction: Action {
  case changeName
}

class AppReducer: Reducer {
  func reduce(state: inout AppState, action: Action) {
    switch action {
    case AppAction.changeName:
      state.name = "Changed Name"
    default:
      break
    }
  }
}

typealias AppStore = Store<AppReducer>

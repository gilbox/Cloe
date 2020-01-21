// Created by Gil Birman on 1/11/20.

import Cloe

struct AppState {
  var appName = "Demo App"
  var age = 6
  var names = ["hank", "cloe", "spike", "joffrey", "fido", "kahlil", "malik"]

  static let initialValue = AppState()
}

enum AppAction: Action {
  case growup
}

let appReducer: Reducer<AppState> = { (state: inout AppState, action: Action) in
  guard let action = action as? AppAction else { return }
  switch action {
  case .growup:
    state.age += 1
  }
}

extension Store {
  func dispatch(_ action: AppAction) {
    dispatch(action as Action)
  }

  subscript(_ action: AppAction) -> (() -> Void) {
    { [weak self] in self?.dispatch(action as Action) }
  }
}

typealias AppStore = Store<AppState>

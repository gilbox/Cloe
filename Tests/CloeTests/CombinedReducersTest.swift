// Created by Gil Birman on 1/20/20.

import XCTest
@testable import Cloe

final class CombinedReducersTests: XCTestCase {
  func testCombinesReducers() {
    enum AppAction2: Action {
      case changeName2
    }

    let AppReducer2: Reducer<AppState> = { state, action in
      switch action {
      case AppAction.changeName:
        state.age = 111
      case AppAction2.changeName2:
        state.name = "Changed Name2"
      default:
        break
      }
    }

    let appStore = Store(
      reducer: combinedReducers(appReducer, AppReducer2),
      state: AppState(),
      middlewares: [])

    appStore.dispatch(AppAction.changeName)
    XCTAssertEqual(appStore.state.name, "Changed Name")
    XCTAssertEqual(appStore.state.age, 111)
    appStore.dispatch(AppAction2.changeName2)
    XCTAssertEqual(appStore.state.name, "Changed Name2")
  }

  static var allTests = [
    ("testCombinesReducers", testCombinesReducers),
  ]
}

// Created by Gil Birman on 1/18/20.

import Combine
import XCTest
@testable import Cloe

final class CloeTests: XCTestCase {
  private var appStore: AppStore!

  override func setUp() {
    super.setUp()
    appStore = Store(
      reducer: appReducer,
      state: AppState(),
      middlewares: [])
  }

  func testSubStatePublisher_PublishesStateNotDeduped() {
    struct NameState: Equatable {
      var name: String
    }

    var values = [NameState]()

    XCTAssertEqual(appStore.state.name, "Initial")

    var cancellables = Set<AnyCancellable>()

    appStore.subStatePublisher { state in
      NameState(name: state.name)
    }
      .sink { subState in
        values.append(subState)
      }
      .store(in: &cancellables)

    appStore.dispatch(AppAction.changeName)
    appStore.dispatch(AppAction.changeName)
    appStore.dispatch(AppAction.changeName)

    XCTAssertEqual(values.map { $0.name }, ["Initial", "Changed Name", "Changed Name", "Changed Name"])
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  func testUniqueSubStatePublisher_PublishesStateDeduped() {
    struct NameState: Equatable {
      var name: String
    }

    var values = [NameState]()

    XCTAssertEqual(appStore.state.name, "Initial")

    var cancellables = Set<AnyCancellable>()

    appStore.uniqueSubStatePublisher { state in
      NameState(name: state.name)
    }
      .sink { subState in
        values.append(subState)
      }
      .store(in: &cancellables)

    appStore.dispatch(AppAction.changeName)
    appStore.dispatch(AppAction.changeName)
    appStore.dispatch(AppAction.changeName)

    XCTAssertEqual(values.map { $0.name }, ["Initial", "Changed Name"])
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  func testSubscript_ReturnsDispatchClosure() {
    XCTAssertEqual(appStore.state.name, "Initial")
    appStore[AppAction.changeName]()
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  static var allTests = [
    ("testUniqueSubStatePublisher_PublishesStateDeduped", testUniqueSubStatePublisher_PublishesStateDeduped),
    ("testSubStatePublisher_PublishesStateNotDeduped", testSubStatePublisher_PublishesStateNotDeduped),
    ("testSubscript_ReturnsDispatchClosure", testSubscript_ReturnsDispatchClosure),
  ]
}

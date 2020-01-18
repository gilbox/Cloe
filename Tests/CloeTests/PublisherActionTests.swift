// Created by Gil Birman on 1/18/20.

import Combine
import XCTest
@testable import Cloe

final class PublisherActionTests: XCTestCase {
  private var appStore: AppStore!

  override func setUp() {
    super.setUp()
    appStore = Store(
      reducer: AppReducer(),
      state: AppState(),
      middlewares: [createPublisherMiddleware()])
  }

  func testProvidesValidGetStateFunction() {
    var name: String?

    appStore.dispatch(PublisherAction<AppState> { dispatch, getState, cancellables in
      name = getState()?.name
    })

    XCTAssertEqual(name, "Initial")
  }

  func testDoesNotRetain() {
    let dontExpect = self.expectation(description: "completed async operation")
    dontExpect.isInverted = true

    let action = PublisherAction<AppState> { [weak dontExpect] dispatch, getState, cancellables in
      let _ = asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation?.fulfill()
        }
    }

    appStore.dispatch(action)

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Initial")
  }

  func testMiddlewareDoesNotRetainCancellables() {
    let dontExpect = self.expectation(description: "completed async operation")
    dontExpect.isInverted = true

    appStore.dispatch(PublisherAction<AppState> { [weak dontExpect] dispatch, getState, cancellables in
      let _ = asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation?.fulfill()
        }
        .store(in: &cancellables)
    })

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Initial")
  }

  func testRetainsCancellables() {
    let expectation = self.expectation(description: "completed async operation")

    let action = PublisherAction<AppState> { [weak expectation] dispatch, getState, cancellables in
      let _ = asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation?.fulfill()
        }
        .store(in: &cancellables)
    }

    appStore.dispatch(action)

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  static var allTests = [
    ("testProvidesValidGetStateFunction", testProvidesValidGetStateFunction),
    ("testDoesNotRetain", testDoesNotRetain)
    ("testMiddlewareDoesNotRetainCancellables", testMiddlewareDoesNotRetainCancellables),
    ("testRetainsCancellables", testRetainsCancellables),
  ]
}

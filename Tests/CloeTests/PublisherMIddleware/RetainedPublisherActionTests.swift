// Created by Gil Birman on 1/18/20.

import Combine
import XCTest
@testable import Cloe

final class RetainedPublisherActionTests: XCTestCase {
  private var appStore: AppStore!

  override func setUp() {
    super.setUp()
    appStore = Store(
      reducer: appReducer,
      state: AppState(),
      middlewares: [createPublisherMiddleware()])
  }

  func testProvidesValidGetStateFunction() {
    var name: String?

    appStore.dispatch(RetainedPublisherAction<AppState> { dispatch, getState, cancellables, cleanup in
      name = getState()?.name
    })

    XCTAssertEqual(name, "Initial")
  }

  func testDoesNotRetainWithoutCancellables() {
    let dontExpect = self.expectation(description: "completed async operation")
    dontExpect.isInverted = true

    appStore.dispatch(RetainedPublisherAction<AppState> { [weak dontExpect] dispatch, getState, cancellables, cleanup in
      let _ = asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          dontExpect?.fulfill()
        }
    })

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Initial")
  }

  func testMiddlewareRetainsCancellables() {
    let expectation = self.expectation(description: "completed async operation")

    appStore.dispatch(RetainedPublisherAction<AppState> { [weak expectation] dispatch, getState, cancellables, cleanup in
      asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation?.fulfill()
        }
        .store(in: &cancellables)
    })

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  func testCleansUpWhenCleanupIsCalledNTimes() {
    let dontExpect = self.expectation(description: "completed async operation")
    dontExpect.isInverted = true

    appStore.dispatch(RetainedPublisherAction<AppState> { [weak dontExpect] dispatch, getState, cancellables, cleanup in
      asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          dontExpect?.fulfill()
        }
        .store(in: &cancellables)

      asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          dontExpect?.fulfill()
        }
        .store(in: &cancellables)

      DispatchQueue.main.async {
        cleanup()
        cleanup()
      }
    })

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Initial")
  }

  func testDoesntCleanUpWhenCleanupIsCalledLessThanNTimes() {
    let expectation1 = self.expectation(description: "completed async operation 1")
    let expectation2 = self.expectation(description: "completed async operation 2")

    appStore.dispatch(RetainedPublisherAction<AppState> { [weak expectation1, weak expectation2] dispatch, getState, cancellables, cleanup in
      asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation1?.fulfill()
        }
        .store(in: &cancellables)

      asyncPublisher()
        .sink(receiveCompletion: { _ in
        }) { _ in
          dispatch(AppAction.changeName)
          expectation2?.fulfill()
        }
        .store(in: &cancellables)

      DispatchQueue.main.async {
        cleanup()
      }
    })

    waitForExpectations(timeout: 0.1, handler: nil)
    XCTAssertEqual(appStore.state.name, "Changed Name")
  }

  static var allTests = [
    ("testProvidesValidGetStateFunction", testProvidesValidGetStateFunction),
    ("testDoesNotRetainWithoutCancellables", testDoesNotRetainWithoutCancellables),
    ("testMiddlewareRetainsCancellables", testMiddlewareRetainsCancellables),
    ("testCleansUpWhenCleanupIsCalledNTimes", testCleansUpWhenCleanupIsCalledNTimes),
    ("testDoesntCleanUpWhenCleanupIsCalledLessThanNTimes", testDoesntCleanUpWhenCleanupIsCalledLessThanNTimes)
  ]
}

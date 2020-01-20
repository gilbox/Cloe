// Created by Gil Birman on 1/18/20.

import Combine
import XCTest
@testable import Cloe

final class HandleCleanupTests: XCTestCase {
  func testSync_CallsCleanupOnce() {
    var calledCount = 0
    let cleanup = { calledCount += 1 }
    let _ = Just(1)
      .handleCleanup(cleanup)
      .sink { _ in }

    XCTAssertEqual(calledCount, 1)
  }

  func testAsync_CallsCleanupOnce() {
    let expectation = self.expectation(description: "called cleanup")
    let dontExpect = self.expectation(description: "don't call again")
    dontExpect.isInverted = true

    var calledCount = 0
    let cleanup = {
      calledCount += 1
      expectation.fulfill()
      if calledCount > 1 {
        dontExpect.fulfill()
      }
    }
    var cancellables = Set<AnyCancellable>()
    asyncPublisher()
      .handleCleanup(cleanup)
      .sink { _ in }
      .store(in: &cancellables)

    waitForExpectations(timeout: 0.1)
    XCTAssertEqual(calledCount, 1)
  }

  func testAsync_CancelledPublisherCallsCleanupOnce() {
    let expectation = self.expectation(description: "called cleanup")
    let dontExpect = self.expectation(description: "don't call again")
    dontExpect.isInverted = true

    var calledCount = 0
    let cleanup = {
      calledCount += 1
      expectation.fulfill()
      if calledCount > 1 {
        dontExpect.fulfill()
      }
    }
    let cancel = asyncPublisher()
      .handleCleanup(cleanup)
      .sink { _ in }

    cancel.cancel()

    waitForExpectations(timeout: 0.1)
    XCTAssertEqual(calledCount, 1)
  }

  func testAsync_ErrorPublisherCallsCleanupOnce() {
    let expectation = self.expectation(description: "called cleanup")
    let dontExpect = self.expectation(description: "don't call again")
    dontExpect.isInverted = true

    var calledCount = 0
    let cleanup = {
      calledCount += 1
      expectation.fulfill()
      if calledCount > 1 {
        dontExpect.fulfill()
      }
    }
    var cancellables = Set<AnyCancellable>()
    asyncErrorPublisher()
      .handleCleanup(cleanup)
      .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
      .store(in: &cancellables)

    waitForExpectations(timeout: 0.1)
    XCTAssertEqual(calledCount, 1)
  }

  // TODO: Figure out how to trigger completion and cancellation

  static var allTests = [
    ("testSync_CallsCleanupOnce", testSync_CallsCleanupOnce),
    ("testAsync_CallsCleanupOnce", testAsync_CallsCleanupOnce),
    ("testAsync_CancelledPublisherCallsCleanupOnce", testAsync_CancelledPublisherCallsCleanupOnce),
    ("testAsync_ErrorPublisherCallsCleanupOnce", testAsync_ErrorPublisherCallsCleanupOnce),
  ]
}

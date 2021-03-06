// Created by Gil Birman on 1/20/20.

import Combine
import XCTest
@testable import Cloe

final class PublisherStateDispatcherTests: XCTestCase {
  struct AppState {
    var foo: PublisherState<Int, Never> = .initial
  }

  func testCompletingPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state)
    }

    let publisher = PassthroughSubject<Int, Never>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink { _ in }
      .store(in: &cancellables)

    publisher.send(8)
    publisher.send(420)
    publisher.send(completion: .finished)

    if case .loading = states[0].foo {} else {
      XCTFail("Expected .loading state")
    }

    if case .loadingWithOutput(let value) = states[1].foo {
      XCTAssertEqual(value, 8)
    } else {
      XCTFail(".loadingWithOutput != \(states[1])")
    }

    if case .loadingWithOutput(let value) = states[2].foo {
      XCTAssertEqual(value, 420)
    } else {
      XCTFail(".loadingWithOutput  != \(states[2])")
    }

    if case .completedWithOutput(let value) = states[3].foo {
      XCTAssertEqual(value, 420)
    } else {
      XCTFail("Expect .completed state")
    }

    XCTAssertEqual(states.count, 4)
  }

  func testCompletingWithoutOutputPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state)
    }

    let publisher = PassthroughSubject<Int, Never>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink { _ in }
      .store(in: &cancellables)

    publisher.send(completion: .finished)

    if case .loading = states[0].foo {} else {
      XCTFail("Expected .loading state")
    }

    if case .completed = states[1].foo {} else {
      XCTFail("Expect .completed state")
    }

    XCTAssertEqual(states.count, 2)
  }

  func testFailingPublisher() {
    enum MyError: Error { case oops }
    struct AppState {
      var foo: PublisherState<Int, MyError> = .initial
    }
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state)
    }

    let publisher = PassthroughSubject<Int, MyError>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink(receiveCompletion: {_ in}, receiveValue: {_ in})
      .store(in: &cancellables)

    publisher.send(8)
    publisher.send(420)
    publisher.send(completion: .failure(.oops))

    if case .loading = states[0].foo {} else {
      XCTFail("Expected .loading state")
    }

    if case .loadingWithOutput(let value) = states[1].foo {
      XCTAssertEqual(value, 8)
    } else {
      XCTFail(".loadingWithOutput != \(states[1])")
    }

    if case .loadingWithOutput(let value) = states[2].foo {
      XCTAssertEqual(value, 420)
    } else {
      XCTFail(".loadingWithOutput  != \(states[2])")
    }

    if case .failed(_) = states[3].foo {} else {
      XCTFail("Expect .failed state")
    }

    XCTAssertEqual(states.count, 4)
  }

  func testCancellingPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state)
    }

    let publisher = PassthroughSubject<Int, Never>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink(receiveCompletion: {_ in}, receiveValue: {_ in})
      .store(in: &cancellables)

    publisher.send(8)
    publisher.send(420)
    cancellables.removeAll()

    if case .loading = states[0].foo {} else {
      XCTFail("Expected .loading state")
    }

    if case .loadingWithOutput(let value) = states[1].foo {
      XCTAssertEqual(value, 8)
    } else {
      XCTFail(".loadingWithOutput != \(states[1])")
    }

    if case .loadingWithOutput(let value) = states[2].foo {
      XCTAssertEqual(value, 420)
    } else {
      XCTFail(".loadingWithOutput  != \(states[2])")
    }

    if case .cancelled = states[3].foo {} else {
      XCTFail("Expect .cancelled state")
    }

    XCTAssertEqual(states.count, 4)
  }

  static var allTests = [
    ("testCompletingPublisher", testCompletingPublisher),
    ("testCompletingWithoutOutputPublisher", testCompletingWithoutOutputPublisher),
    ("testFailingPublisher", testFailingPublisher),
    ("testCancellingPublisher", testCancellingPublisher),
  ]
}

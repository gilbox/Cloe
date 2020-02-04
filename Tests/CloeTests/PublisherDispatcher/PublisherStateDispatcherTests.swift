// Created by Gil Birman on 1/20/20.

import Combine
import XCTest
@testable import Cloe

final class PublisherStateDispatcherTests: XCTestCase {
  struct AppState {
<<<<<<< Updated upstream
    var foo: PublisherState<Int, Never> = .initial
=======
    var foo: PublisherState<Int> = .initial

    func copy() -> AppState {
      AppState(foo: foo.copy())
    }
>>>>>>> Stashed changes
  }

  func testCompletingPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state.copy())
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

    XCTAssertEqual(states[0].foo.status, .loading)
    XCTAssertEqual(states[0].foo.output, nil)

    XCTAssertEqual(states[1].foo.status, .loading)
    XCTAssertEqual(states[1].foo.output, 8)

    XCTAssertEqual(states[2].foo.status, .loading)
    XCTAssertEqual(states[2].foo.output, 420)

    XCTAssertEqual(states[3].foo.status, .completed)
    XCTAssertEqual(states[3].foo.output, 420)

    XCTAssertEqual(states.count, 4)
  }

  func testCompletingWithoutOutputPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state.copy())
    }

    let publisher = PassthroughSubject<Int, Never>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink { _ in }
      .store(in: &cancellables)

    publisher.send(completion: .finished)

    XCTAssertEqual(states[0].foo.status, .loading)

    XCTAssertEqual(states[1].foo.status, .completed)
    XCTAssertEqual(states[1].foo.output, nil)

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
      states.append(state.copy())
    }

<<<<<<< Updated upstream
=======
    enum MyError: Error, Equatable { case oops }
>>>>>>> Stashed changes
    let publisher = PassthroughSubject<Int, MyError>()
    var cancellables = Set<AnyCancellable>()

    publisher
      .stateDispatcher(dispatch, statePath: \AppState.foo)
      .sink(receiveCompletion: {_ in}, receiveValue: {_ in})
      .store(in: &cancellables)

    publisher.send(8)
    publisher.send(420)
    publisher.send(completion: .failure(.oops))

    XCTAssertEqual(states[0].foo.status, .loading)

    XCTAssertEqual(states[1].foo.status, .loading)
    XCTAssertEqual(states[1].foo.output, 8)

    XCTAssertEqual(states[2].foo.status, .loading)
    XCTAssertEqual(states[2].foo.output, 420)

    XCTAssertEqual(states[3].foo.status, .failed)
    XCTAssertEqual(states[3].foo.error as? MyError, MyError.oops)

    XCTAssertEqual(states.count, 4)
  }

  func testCancellingPublisher() {
    var states = [AppState]()
    var state = AppState()
    let dispatch: (Action) -> Void = { action in
      guard let action = action as? PublisherDispatcherAction<AppState> else { return }
      action.update(&state)
      states.append(state.copy())
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

    XCTAssertEqual(states[0].foo.status, .loading)
    XCTAssertEqual(states[0].foo.output, nil)

    XCTAssertEqual(states[1].foo.status, .loading)
    XCTAssertEqual(states[1].foo.output, 8)

    XCTAssertEqual(states[2].foo.status, .loading)
    XCTAssertEqual(states[2].foo.output, 420)

    XCTAssertEqual(states[3].foo.status, .cancelled)
    XCTAssertEqual(states[3].foo.output, 420)

    XCTAssertEqual(states.count, 4)
  }

  static var allTests = [
    ("testCompletingPublisher", testCompletingPublisher),
    ("testCompletingWithoutOutputPublisher", testCompletingWithoutOutputPublisher),
    ("testFailingPublisher", testFailingPublisher),
    ("testCancellingPublisher", testCancellingPublisher),
  ]
}

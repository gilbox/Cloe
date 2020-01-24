// Created by Gil Birman on 1/11/20.

import Cloe
import Combine
import SwiftUI

struct ContentView: View {
  @State var index = 0

  var body: some View {
    VStack {
      Spacer()
      Text(store.state.appName).font(.title)
      MyChild(index: index)
        .padding()
        .border(Color.gray)
        .padding()
      Button("Next person") {
        self.index = self.index == self.store.state.names.count - 1
          ? 0
          : self.index + 1
      }
      Spacer()
    }.padding()
  }

  @EnvironmentObject private var store: AppStore
}

struct MyChild: View {

  // MARK: Internal

  var index: Int

  var body: some View {
    Connect(store: store, selector: selector, content: body)
  }

  // MARK: Private

  @EnvironmentObject private var store: AppStore

  private let delayedGrowup = PublisherAction<AppState>(description: "delayedGrowup") { dispatch, getState, cancellables in
    Just(())
      .delay(for: 2, scheduler: RunLoop.main)
      .statusDispatcher(dispatch, statePath: \AppState.growupStatus, description: "growup status")
      .sink { _ in
        dispatch(AppAction.growup)
      }
      .store(in: &cancellables)
  }

  private struct MyChildState: Equatable {
    var age: Int
    var name: String
  }

  private func body(_ state: MyChildState) -> some View {
    VStack {
      Text("I'm \(state.age).")
      Text("My name is \(state.name)")
      Button("Grow up", action: store[.growup])
      Button("Grow up delayed 2s") { self.store.dispatch(self.delayedGrowup) }
    }
  }

  private func selector(_ state: AppState) -> MyChildState {
    .init(age: state.age, name: state.names[index])
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

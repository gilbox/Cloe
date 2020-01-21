// Created by Gil Birman on 1/18/20.

import Foundation
import SwiftUI

/// Inject a Cloe Store into a SwiftUI view
///
/// Example usage:
///
///     struct MyView: View {
///       // Inject your store
///       @EnvironmentObject var store: AppStore
///
///       // Connect to the store
///       var body: some View {
///         ConnectStore(store: store, content: body)
///       }
///
///       // Render something using the state
///       private func body(_ state: MyState) -> some View {
///         Text("Hello \(state.name)!")
///       }
///     }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct ConnectStore<State, Content: View>: View {

  // MARK: Public

  public var store: Store<State>
  public var content: (State) -> Content

  public init(
    store: Store<State>,
    content: @escaping (State) -> Content)
  {
    self.store = store
    self.content = content
  }

  public var body: some View {
    Group {
      (state ?? store.state).map(content)
    }.onReceive(store.statePublisher) { state in
      self.state = state
    }
  }

  // MARK: Private

  @SwiftUI.State private var state: State?
}

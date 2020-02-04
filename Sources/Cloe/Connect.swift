// Created by Gil Birman on 1/11/20.

import Combine
import SwiftUI

/// Inject a Cloe Store into a SwiftUI view
///
/// Example usage:
///
///     struct MyView: View {
///       var index: Int
///
///       // Define your derived state
///       struct MyDerivedState: Equatable {
///         var age: Int
///         var name: String
///       }
///
///       // Inject your store
///       @EnvironmentObject var store: AppStore
///
///       // Connect to the store
///       var body: some View {
///         Connect(store: store, selector: selector, content: body)
///       }
///
///       // Setup a state selector
///       private func selector(_ state: AppState) -> MyDerivedState {
///         .init(age: state.age, name: state.names[index])
///       }
///
///       // Render something using the selected state
///       private func body(_ state: MyDerivedState) -> some View {
///         Text("Hello \(state.name)!")
///       }
///     }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct Connect<State, SubState: Equatable, Content: View>: View {

  // MARK: Public

  public var store: Store<State>
  public var selector: StateSelector<State, SubState>
  public var content: (SubState) -> Content

  public init(
    store: Store<State>,
    selector: @escaping StateSelector<State, SubState>,
    content: @escaping (SubState) -> Content)
  {
    self.store = store
    self.selector = selector
    self.content = content
    self.publisher = store.uniqueSubStatePublisher(selector)
  }

  public var body: some View {
    Group {
      (state ?? selector(store.state)).map(content)
    }.onReceive(publisher) { state in
      print(">>>xxx ", ObjectIdentifier(self.foo))
      self.state = state
    }
  }

  public typealias Effect = (AnyPublisher<SubState, Never>, inout Set<AnyCancellable>) -> Void

  public func effect(_ closure: Effect) -> Self {
    var copy = self
    closure(publisher, &copy.cancellables)
    return copy
  }

  // MARK: Private

  private class Foo {}

  @SwiftUI.State private var state: SubState?
  @SwiftUI.State private var foo = Foo()
  private let publisher: AnyPublisher<SubState, Never>
  private var cancellables = Set<AnyCancellable>()
}

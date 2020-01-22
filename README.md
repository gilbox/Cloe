# Cloe

[![CI Status](http://img.shields.io/travis/gilbox/Cloe.svg?style=flat)](https://travis-ci.org/gilbox/Cloe)
![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/gilbox/Cloe)
[![License](https://img.shields.io/github/license/gilbox/Cloe)](LICENSE)

**Cloe is Redux on Combine for SwiftUI with excellent feng shui.**

## Setup your store

```swift
struct AppState {
  var appName = "Demo App"
  var age = 6
  var names = ["hank", "cloe", "spike", "joffrey", "fido", "kahlil", "malik"]

  static let initialValue = AppState()
}

enum AppAction: Action {
  case growup
}

typealias AppStore = Store<AppReducer>
```

## Setup your reducer

```swift
func appReducer(state: inout AppState, action: Action) {
  guard let action = action as? AppAction else { return }
  switch action {
  case .growup:
    state.age += 1
  }
}
```
    
## Instantiate your Store

```swift
// Create a store with the publisher middleware
// this middleware allows us to use `PublisherAction`
// later to dispatch an async action.
let store = AppStore(
  reducer: appReducer,
  state: .initialValue,
  middlewares: [createPublisherMiddleware()])

// Inject the store with `.environmentObject()`.
// Alternatively we could inject it with `.environment()`
let contentView = ContentView().environmentObject(store)

// later...
    window.rootViewController = UIHostingController(rootView: contentView)
```

## (Optionally) add some convenience extensions to the store

These extensions improve the ergonomics of working with the store. With the built-in
`dispatch` function we would normally dispatch with `store.dispatch(AppAction.growup)`.
With this `dispatch` extension we can do `store.dispatch(.growup)` instead.

The `subscript` extension allows us to avoid using a closure with SwiftUI views.
For example, a button can be implemented with: `Button("Grow up", action: store[.growup])`.

```swift
extension Store {
  func dispatch(_ action: AppAction) {
    dispatch(action as Action)
  }

  subscript(_ action: AppAction) -> (() -> Void) {
    { [weak self] in self?.dispatch(action as Action) }
  }
}
```

## Connect your SwiftUI View to your store

This is an example of injecting state using a state selector. Here were define 
the state selector inside of the View, but it can be defined anywhere.

```swift
struct MyView: View {
  var index: Int

  // Define your derived state
  struct MyDerivedState: Equatable {
    var age: Int
    var name: String
  }

  // Inject your store
  @EnvironmentObject var store: AppStore

  // Connect to the store
  var body: some View {
    Connect(store: store, selector: selector, content: body)
  }

  // Render something using the selected state
  private func body(_ state: MyDerivedState) -> some View {
    Text("Hello \(state.name)!")
  }
  
  // Setup a state selector
  private func selector(_ state: AppState) -> MyDerivedState {
    .init(age: state.age, name: state.names[index])
  }
}
```

If you want to connect to the state of the store without defining a selector,
use `ConnectStore` instead. Note that `ConnectStore` does not currently skip 
duplicate states the way that `Connect` does.

## Dispatching a simple action

Here's how you can dispatch a simple action:

```swift
    Button("Grow up") { self.store.dispatch(AppAction.growup) }
    
    // ... or ...
    
    Button("Grow up", action: store[AppAction.growup])
```

Or with the optional [`Store` extension](https://github.com/gilbox/Cloe#optionally-add-some-convenience-extensions-to-the-store) mentioned above:
    
```swift

    Button("Grow up") { self.store.dispatch(.growup) }

    // ...or...

    Button("Grow up", action: store[.growup])
```

## Dispatching an async action with the publisher middleware

Below is a simple example, read more about publisher middleware [here](./Sources/Cloe/PublisherMiddleware/README.md).

```swift

    Button("Grow up") { self.store.dispatch(self.delayedGrowup) }
    
  //...

  private let delayedGrowup = PublisherAction<AppState> { dispatch, getState, cancellables in
    Just(())
      .delay(for: 2, scheduler: RunLoop.main)
      .sink { _ in
        dispatch(AppAction.growup)
      }
      .store(in: &cancellables)
  }
```

## Tracking async task progress with publisher dispatcher

[Publisher dispatcher documentation](./Sources/Cloe/PublisherDispatcher/README.md).

## How is it different from ReSwift?

- ReSwift is battle tested.
- ReSwift is being used in real production apps.
- Cloe uses [Combine Publishers](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Cloe.swift) instead of a [bespoke StoreSubscriber](https://github.com/ReSwift/ReSwift/blob/master/ReSwift/CoreTypes/StoreSubscriber.swift) 
- Cloe's [Middleware](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Cloe.swift) is simpler than [ReSwift's Middleware](https://github.com/ReSwift/ReSwift/blob/master/ReSwift/CoreTypes/Middleware.swift) but achieves the same level of flexibility.
- Cloe's [combineMiddleware](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Cloe.swift) function is simpler and easier-to-read.
- Cloe provides a slick way to connect your SwiftUI views.
- Cloe does not have a skip-repeats option for the main Store state, but when you [`Connect`](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Connect.swift) it to a SwiftUI component it always skips repeated states (subject to change).

## Why does the `Store` object conform to `ObservableObject`?

You may have noticed that Cloe's [`Store`](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Cloe.swift) class conforms to [`ObservableObject`](https://developer.apple.com/documentation/combine/observableobject).
However, the `Store` **does not contain any `@Published` properties**. This conformance 
is only added to make it easy to inject your store with [`.environmentObject()`](https://developer.apple.com/documentation/swiftui/environmentobject).
However, since we don't expose any `@Published` vars don't expect a view with

```swift
@ObservedObject var store: AppStore
```

to automatically re-render when the store changes. This design is intentional so you can 
[subscribe](https://github.com/gilbox/Cloe#connect-your-swiftui-view-to-your-store) to more granular updates with [`Connect`](https://github.com/gilbox/Cloe/blob/master/Sources/Cloe/Connect.swift).

## Example

To run the example project, clone this repo, and open iOS Example.xcworkspace from the iOS Example directory.


## Requirements

- iOS 13
- macOS 10.15
- watchOS 6
- tvOS 13

## Installation

Add this to your project using Swift Package Manager. In Xcode that is simply: File > Swift Packages > Add Package Dependency... and you're done. Alternative installations options are shown below for legacy projects.

### CocoaPods

If you are already using [CocoaPods](http://cocoapods.org), just add 'Cloe' to your `Podfile` then run `pod install`.

### Carthage

If you are already using [Carthage](https://github.com/Carthage/Carthage), just add to your `Cartfile`:

```ogdl
github "gilbox/Cloe" ~> 0.3.0
```

Then run `carthage update` to build the framework and drag the built `Cloe`.framework into your Xcode project.


## License

Cloe is available under the MIT license. See [the LICENSE file](LICENSE) for more information.

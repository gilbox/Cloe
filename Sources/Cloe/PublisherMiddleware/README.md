# Publisher middleware

## Overview

The publisher middleware handles the dispatch of publisher actions. A publisher action
is a Cloe action that behaves very much like a thunk, but also helps manage retaining a `Set` of
`AnyCancellable` objects.

## Setup

Add publisher middleware to your store:

```swift
let store = AppStore(
  reducer: AppReducer(),
  state: .initialValue,
  middlewares: [createPublisherMiddleware()])
```

## Actions

Publisher middleware includes 2 types of actions:

1. `PublisherAction`: Stores a `Set` of `AnyCancellable` objects.
    You are responsible to retaining the `PublisherAction` while the `Combine` pipelines are running.
2. `RetainedPublisherAction`: The `Set` of `AnyCancellable` objects are stored by the middleware.
    You don't have to retain the `RetainedPublisherAction` instance, the middleware will do it for you.

## Deciding when to use `PublisherAction` vs `RetainedPublisherAction`

Do you always want your action's pipelines to live until completion/cancellation?

- Use `RetainedPublisherAction`

Do you want your action's pipelines to live only so long as a certain view is displayed?

- Use `PublisherAction`

## `PublisherAction`

```swift
PublisherAction<MyState> { dispatch, getState, cancellables in
    myPublisher1
      ...
      .tap { ... }
      .store(in: &cancellables)
    myPublisher2
      ...
      .tap { ... }
      .store(in: &cancellables)
    ...
  }
```

Alternate syntax:

```swift
PublisherAction<MyState> { context in
    myPublisher1
      ...
      .tap { ... }
      .store(in: &context.cancellables)
    myPublisher2
      ...
      .tap { ... }
      .store(in: &context.cancellables)
    ...
  }
```

## `RetainedPublisherAction`

```swift
RetainedPublisherAction<MyState> { dispatch, getState, cancellables, cleanup in
  myPublisher1
    ...
    .handleCleanup(cleanup)
    .tap { ... }   // <-- handleCleanup and store sandwhich the subscriber that returns AnyCancellable
    .store(in: &cancellables)
  myPublisher2
    ...
    .handleCleanup(cleanup)
    .tap { ... }
    .store(in: &cancellables)
  ...
}
```

Alternate syntax:

```swift
RetainedPublisherAction<MyState> { context in
  myPublisher1
    ...
    .handleCleanup(context.cleanup)
    .tap { ... }   // <-- handleCleanup and store sandwhich the subscriber that returns AnyCancellable
    .store(in: &context.cancellables)
  myPublisher2
    ...
    .handleCleanup(context.cleanup)
    .tap { ... }
    .store(in: &context.cancellables)
  ...
}
```
### `handleCleanup`

`handleCleanup` (as seen in the previous code example)
is an extension of `Publisher` that simply executes
the provided callback `cleanup` on cancellation or completion of
the pipeline. It will only call `cleanup()` one time.

```
extension Publisher {
  public func handleCleanup(_ cleanup: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
    let complete = Box(false)
    return handleEvents(
      receiveCompletion: { _ in
        if complete.value { return }
        complete.value = true
        cleanup()
      },
      receiveCancel: {
        if complete.value { return }
        complete.value = true
        cleanup()
      })
  }
}
```

### `RetainedPublisherAction` Discussion

```swift
RetainedPublisherAction<MyState> { dispatch, getState, cancellables, cleanup in
  ...
}
```

The `inout cancellables` argument is initially provided to you as an empty
set of `AnyCancellable` objects, ie, `Set<AnyCancellable>()`. You are responsible
for filling this set with the cancellable objects that you want the publisher
middleware to retain for you (the easiest way is to use the `.receive(on:)` operator).

The `cleanup` function that is provided to you when you instantiate
a `RetainedPublisherAction`. `cleanup()` decrements a counter every time it's
called. When that count reaches 0, all of your cancellables are released
by the middleware.

Ensuring that the middleware releases your cancellables correctly is easy, just make 
sure to sandwhich your last subscriber in every pipeline (eg., `sink`) between
`handleError(_:)` and `receive(on:)`

```swift
myPublisher
  ...
  .handleCleanup(cleanup)
  .tap { ... }    // <-- Sandwhiched subscriber
  .store(in: &cancellables)
```

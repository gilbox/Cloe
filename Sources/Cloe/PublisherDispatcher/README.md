# Publisher dispatcher

## Overview

The publisher dispatcher handles a common task in a Redux application where there is some
async task and we need to track the progress of that task. We may need to know that the
task is *loading*, or *completed*, or that it has *failed* or been *cancelled*.

The publisher dispatcher turns this:

```swift
  dispatch(AppAction.documentSave.loading)
  document.save()
    .handleEvents(receiveCancel: {
      dispatch(AppAction.documentSave.cancelled)
    })
    .sink(
      receiveCompletion: { completion in
        if case .failure(let error) = completion {
          dispatch(AppAction.documentSave.failed(error))
        }
      },
      receiveValue: { version in
        dispatch(AppAction.documentSave.finished(version))
      }
    .store(in: &cancellables)
```

into this:

```swift
  document.save()
    .statusDispatcher(dispatch, statePath: \AppState.saveStatus)
    .sink(receiveCompletion: { _ in}, receiveValue: {_ in })
    .store(in: &cancellables)
```

## Usage: `PublisherStatus`

Use `PublisherStatus` when you only need to track the status of the publisher, not it's output.

First declare an object in your store:

```swift
  var saveStatus: PublisherStatus<Error> = .initial
```

Then inside of a `PublisherAction` or `RetainedPublisherAction`:

```swift
  publisher
    .statusDispatcher(dispatch, statePath: \AppState.saveStatus)
```

## Usage: `PublisherState`

Use `PublisherState` when you'd also like to track the most recent output of your Publisher.

First declare an object in your store:

```swift
  var saveStatus: PublisherState<Document, Error> = .initial
```

Then inside of a `PublisherAction` or `RetainedPublisherAction`:

```swift
  publisher
    .stateDispatcher(dispatch, statePath: \AppState.saveStatus)
```

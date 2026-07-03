# Macros

DUFAP macros reduce boilerplate while keeping the architecture visible.

## ViewModel

```swift
@ViewModel(action: CounterAction.self)
final class CounterViewModel {
    var state = CounterState()
}
```

`@ViewModel` adds `ViewModelProtocol` conformance, publishes `state`, and provides the cancellation bag and state publisher required by `AnyViewModel`.

## Action

```swift
@Action
enum CounterAction {
    case increment
}
```

`@Action` generates sync and async action subtypes and conversion from the original action.

## Pathable

Use `@Pathable(.case)` when only the route case matters. Use `@Pathable(.value)` when associated values must participate in identity.


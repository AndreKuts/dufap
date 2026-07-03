# Runtime

DUFAP runtime features stay optional.

## Action Lifecycle

Plugins receive lifecycle phases:

- `willTrigger`
- `didTrigger`
- `didCancel`
- `didFail`

## Tracing

Register `ActionTracer` to keep an in-memory timeline of recent actions:

```swift
let tracer = ActionTracer()
ActionPluginRegistry.register(tracer)
```

## Testing

`ViewModelTester` sends actions through the same `AnyViewModel` boundary used by SwiftUI and exposes the resulting state.

## Plugin Patterns

The most useful plugins are usually small and specific.

### Privacy-safe logger

Use `LoggerActionPlugin` together with `LoggableAction` when actions carry email, password, token, or personal data.

### Analytics bridge

Create a small plugin that listens to `didTrigger` and forwards a subset of actions to analytics. This keeps product tracking out of ViewModels.

### Debug timeline

Use `ActionTracer` in debug builds or tests when you need to inspect action order, cancellation, and failure behavior.

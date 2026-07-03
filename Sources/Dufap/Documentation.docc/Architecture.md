# Architecture

DUFAP keeps the UI flow explicit:

1. SwiftUI sends an action.
2. `AnyViewModel` routes it to sync or async handling.
3. The concrete ViewModel mutates state.
4. SwiftUI observes the new state.

Sync actions should be small state transitions. Async actions should call services, await work, and then update state from the MainActor boundary provided by `AnyViewModel`.

## Common Mistakes

- Do not perform expensive work in sync actions.
- Do not log raw sensitive action payloads.
- Do not use background state mutation as an optimization.

## Best Practices

- Use sync actions for typing, toggles, counters, and navigation.
- Use async actions for network, database, file IO, waits, and expensive work.
- Use `LoggableAction` for actions that contain email, password, token, or personal data.


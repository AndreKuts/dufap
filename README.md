#  Dufap is an Xcode Package for Architecture Patterns.

### D - Declarative
### U - Unidirectional
### F - Functional
### A - Architectural
### P - Pattern


# Overview
This Xcode package implements the View-Action-State MVVM architectural pattern for iOS applications, designed to streamline and enhance the management of user interactions and state changes within the app. 
The View-Action-State MVVM pattern introduces a clear separation between the view's actions and its state, providing a more structured approach to handling user interactions and updating the UI. 

This approach combines elements of Redux and MVVM to utilize best practices from both frameworks.

Dufap is a lightweight macro-powered View-Action-State architecture for SwiftUI. It gives you unidirectional flow and testable ViewModels without the complexity of a full TCA setup.

## Why Dufap

Dufap is for apps that want explicit actions, focused state, testable ViewModels, and less boilerplate. It is not trying to replace TCA for every app; it is a smaller architecture layer for teams that like MVVM but want a clearer unidirectional flow.

Use Dufap when:
- Your SwiftUI screens already fit a ViewModel shape.
- You want state changes to happen through explicit actions.
- You want macro-generated boilerplate without hiding the architecture.
- You need privacy-safe logging, cancellation, and tracing hooks.

Avoid Dufap when:
- You need a full reducer/effect/dependency framework across the whole app.
- Your app already uses TCA deeply.
- A screen is simple enough that plain SwiftUI state is clearer.

Compared with MVVM, Dufap makes user events explicit through actions. Compared with Redux, it keeps state local to ViewModels instead of forcing one global store. Compared with TCA, it keeps the core smaller and closer to regular SwiftUI ViewModels.

Inspired by these resources: 

### ViewState MVVM 
- https://github.com/quickbirdeng/SwiftUI-Architectures
- https://quickbirdstudios.com/blog/swiftui-architecture-redux-mvvm/
### TCA
- https://github.com/pointfreeco/swift-composable-architecture
- https://www.pointfree.co/collections/composable-architecture


## Visual diagrams:

![Dufap drawio](https://github.com/user-attachments/assets/45a8cdfa-da99-4b98-874d-5e4c917839ed)


## Key Concepts
  - **Action**: Represents user interactions or events that the ViewModel needs to handle. Actions are sent from the View to the ViewModel to initiate data processing or state changes.
  - **State**: A structure that encapsulates the state of the View. The ViewModel updates the State based on the actions received and the current state.
  - **ViewModel**: The intermediary between the Model and the View. It processes user actions, interacts with the Model, and updates the State. The ViewModel exposes actions that the View can invoke and publishes state changes.
  - **View**: The user interface layer that displays the data and captures user interactions. The view binds to the ViewModel and updates itself based on the State changes.
  - **Model**: The data layer of the application, is responsible for managing the data and business logic. It handles data retrieval, persistence, and any other data-related operations.

## Benefits of View-Action-State MVVM
  - Clear Separation of Concerns: By isolating actions and state, this pattern ensures a clean separation between user interactions and UI state, enhancing modularity and maintainability.
  - Enhanced State Management: The ViewState pattern provides a clear and consistent way to manage UI state, making it easier to understand and debug state changes.
  - Improved Testability: Actions and state updates can be tested independently, ensuring that the ViewModel behaves correctly under different scenarios.
  - Scalable Architecture: This pattern is suitable for applications of all sizes, from simple apps to complex, large-scale projects, providing a scalable and maintainable architecture.

## Features

- State updates should only occur in the ViewModel layer as the View layer only has visibility for reading State.
- Receiving state changes occurs on the Main thread by default, so it's safe to update from any thread.
- Macros are useful for reducing the number of lines of code.
- Protected state the updates.

## Macros
- @ViewWith: Use this macro to create a SwiftUI view that integrates with your ViewModel
- @ViewModel: Use this macro to create a ViewModel that adheres to the ViewModelProtocol.
- @Action: Use this macro to create an action for ViewModel
- Pathable: Automatically generates `Hashable`, `Equatable`, and `Identifiable` conformance for navigation enums, either by case identity or by full value identity.

### Pathable identity

`@Pathable` defaults to `.case` identity. This keeps the original Dufap behavior: equality, hashing, and `id` are based only on the enum case index. Associated values are ignored, so this mode works even when payloads are not `Hashable`.

```swift
@Pathable
enum Route {
    case home
    case profile(ProfileDraft)
}
```

Use `@Pathable(.value)` when associated values are part of the route identity. In this mode Swift synthesizes `Hashable` and `Equatable`, so every associated value must be `Hashable`. The generated `id` is `self`.

```swift
@Pathable(.value)
enum Route {
    case home
    case profile(id: String)
}
```

### Generated code

Macros reduce boilerplate but keep the generated architecture explicit.

You write:

```swift
@Action
enum CounterAction {
    case increment
}

@ViewModel(action: CounterAction.self)
final class CounterViewModel {
    var state = CounterState()
}
```

Dufap generates the action subtypes used for routing:

```swift
enum SyncAction: SyncActionProtocol {
    case increment

    init?(from original: any ActionProtocol) {
        guard let original = original as? CounterAction else { return nil }
        switch original {
        case .increment:
            self = .increment
        }
    }
}

typealias SA = SyncAction
typealias AA = Never
```

And the ViewModel support needed by `AnyViewModel`:

```swift
extension CounterViewModel: ViewModelProtocol { }
```

## Installation

To integrate Dufap into your Swift project, you can use the Swift Package Manager. Add the following to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AndreKuts/dufap.git", from: "2.1.0")
]
```

## Thread Safety

Dufap keeps `ViewModelProtocol` nonisolated, so actions can be triggered from any thread. `AnyViewModel` makes sure state mutations are delivered on the main thread.

Sync actions are immediate UI/state transitions when they are triggered from the main thread:

```swift
viewModel.trigger(action: .queryChanged("dufap"))
```

| Action | Caller thread | Behavior                                                              |
| ------ | ------------- | --------------------------------------------------------------------- |
| Sync   | Main          | Executes inline and updates state before `trigger(action:)` returns   |
| Sync   | Background    | Schedules state mutation on the main thread                           |
| Async  | Any           | Schedules async handler on the MainActor                              |

For UI events such as typing, toggles, and counters, prefer sync actions triggered from the main thread. They execute inline without async scheduling.

If a sync action is triggered from a background thread, `AnyViewModel` schedules it on the main thread asynchronously. This keeps the any-thread convenience without using `DispatchQueue.main.sync`, so there is no cross-thread deadlock risk. Code that needs an immediate state update should call sync actions from the main thread.

Async actions can also be triggered from any thread. `AnyViewModel` schedules them on the MainActor, so ViewModels can update state directly without repeating `await MainActor.run`.

Keep heavy work inside async services. Awaiting a network call, database call, or detached service operation does not block the MainActor; the ViewModel remains focused on state transitions:

```swift
func triggerAsync(action: ContentAction.AsyncAction) async {
    state.isLoading = true

    let result = await service.call()

    state.textInput = result
    state.isLoading = false
}
```

Use sync actions for quick state transitions. Use async actions for network calls, database work, file IO, waits, and expensive computation.

## Privacy Logging

Actions that contain sensitive values should conform to `LoggableAction` and return a masked description. `LoggerActionPlugin` uses `logDescription` when it is available and falls back to `String(describing:)` otherwise.

```swift
extension AuthAction: LoggableAction {
    var logDescription: String {
        switch self {
        case .inputEmail(let email):
            return "inputEmail(\(PrivacyMask.email(email)))"
        case .inputPassword(let password):
            return "inputPassword(\(PrivacyMask.password(password)))"
        }
    }
}
```

For high-frequency UI actions, keep logger overhead low by disabling one side of the lifecycle:

```swift
ActionPluginRegistry.register(
    LoggerActionPlugin(
        logsWillTrigger: false,
        asyncOutput: true
    )
)
```

## Lifecycle and Tracing

Action plugins receive lifecycle events for `willTrigger`, `didTrigger`, `didCancel`, and `didFail`. `LoggerActionPlugin` uses the same privacy-safe descriptions as tracing.

```swift
let tracer = ActionTracer()
ActionPluginRegistry.register(tracer)

viewModel.trigger(action: .search)

let timeline = tracer.traces
```

Use tracing in debug builds or tests when you need to inspect action flow without changing ViewModels.

### Plugin examples

Plugins are a good fit when you want cross-cutting behavior without polluting ViewModels.

Privacy-safe auth logging:

```swift
@Action
enum AuthAction {
    case inputEmail(String)
    case inputPassword(String)
    case login
}

extension AuthAction: LoggableAction {
    var logDescription: String {
        switch self {
        case .inputEmail(let email):
            return "inputEmail(\(PrivacyMask.email(email)))"
        case .inputPassword(let password):
            return "inputPassword(\(PrivacyMask.password(password)))"
        case .login:
            return "login"
        }
    }
}

ActionPluginRegistry.register(
    LoggerActionPlugin(
        logsWillTrigger: false,
        asyncOutput: true
    )
)
```

Analytics plugin that only tracks completed business actions:

```swift
final class AnalyticsActionPlugin: ActionPlugin {

    func willTrigger(action: any ActionProtocol) { }

    func didTrigger(action: any ActionProtocol) {
        switch action {
        case is CheckoutAction:
            Analytics.track("checkout_completed")
        case is SearchAction:
            Analytics.track("search_completed")
        default:
            break
        }
    }
}

ActionPluginRegistry.register(AnalyticsActionPlugin())
```

Debug timeline plugin for local inspection:

```swift
let tracer = ActionTracer(limit: 100)
ActionPluginRegistry.register(tracer)

viewModel.trigger(action: .search)

for trace in tracer.traces {
    print(trace.phase, trace.actionDescription, trace.duration ?? 0)
}
```

For most apps, a good default stack is:
- `LoggerActionPlugin` in debug builds.
- `ActionTracer` in debug builds or tests.
- One small analytics plugin for product events.

## Examples

### Login form with privacy-safe logging

This example shows the smallest useful loop: SwiftUI sends actions, the ViewModel mutates state, and the logger can observe actions without exposing raw credentials.

```swift
import Dufap
import SwiftUI

struct LoginState: StateProtocol {
    var email = ""
    var password = ""
    var isSubmitEnabled = false
}

@Action
enum LoginAction {
    case emailChanged(String)
    case passwordChanged(String)
    case submitTapped
}

extension LoginAction: LoggableAction {
    var logDescription: String {
        switch self {
        case .emailChanged(let email):
            return "emailChanged(\(PrivacyMask.email(email)))"
        case .passwordChanged(let password):
            return "passwordChanged(\(PrivacyMask.password(password)))"
        case .submitTapped:
            return "submitTapped"
        }
    }
}

@ViewModel(action: LoginAction.self)
final class LoginViewModel {

    var state: LoginState

    init(state: LoginState = LoginState()) {
        self.state = state
    }

    func trigger(action: LoginAction.SyncAction) {
        switch action {
        case .emailChanged(let email):
            state.email = email
        case .passwordChanged(let password):
            state.password = password
        case .submitTapped:
            break
        }

        state.isSubmitEnabled = state.email.contains("@") && state.password.count >= 8
    }
}

@ViewWith(state: LoginState.self, action: LoginAction.self)
struct LoginView: View {

    @ObservedObject
    var viewModel: AnyViewModel<LoginState, LoginAction>

    init(_ viewModel: AnyViewModel<LoginState, LoginAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            TextField(
                "Email",
                text: viewModel.binding(\.email, onChange: LoginAction.emailChanged)
            )
            .textContentType(.emailAddress)

            SecureField(
                "Password",
                text: viewModel.binding(\.password, onChange: LoginAction.passwordChanged)
            )
            .textContentType(.password)

            Button("Sign In") {
                viewModel.trigger(action: .submitTapped)
            }
            .disabled(!viewModel.isSubmitEnabled)
        }
        .padding()
    }
}
```

Register the logger once during app startup:

```swift
@main
struct ExampleApp: App {

    init() {
        ActionPluginRegistry.register(LoggerActionPlugin())
    }

    var body: some Scene {
        WindowGroup {
            LoginView(AnyViewModel(LoginViewModel()))
        }
    }
}
```

### Search screen with async work and cancellation

This example separates immediate main-thread state changes from asynchronous work. `queryChanged` is sync, `search` is async, and repeated `.search` actions share the same generated `cancelID`, so the previous search task is cancelled by `AnyViewModel`.

```swift
import Dufap
import SwiftUI

struct SearchState: StateProtocol {
    var query = ""
    var results: [String] = []
    var isLoading = false
    var message = "Type a query"
}

@Action
enum SearchAction {
    case queryChanged(String)
    case clear
    case search

    var triggerMode: TriggerMode {
        switch self {
        case .queryChanged, .clear:
            return .sync
        case .search:
            return .async
        }
    }
}

struct SearchService {
    func search(_ query: String) async throws -> [String] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            "\(query) overview",
            "\(query) examples",
            "\(query) best practices"
        ]
    }
}

@ViewModel(action: SearchAction.self)
final class SearchViewModel {

    var state: SearchState
    private let service: SearchService

    init(state: SearchState = SearchState(), service: SearchService = SearchService()) {
        self.state = state
        self.service = service
    }

    func trigger(action: SearchAction.SyncAction) {
        switch action {
        case .queryChanged(let query):
            state.query = query
            state.message = query.isEmpty ? "Type a query" : "Ready"
        case .clear:
            state = SearchState()
        }
    }

    func triggerAsync(action: SearchAction.AsyncAction) async {
        switch action {
        case .search:
            let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)

            state.isLoading = true
            state.message = "Searching"

            guard !query.isEmpty else {
                state.isLoading = false
                state.message = "Type a query"
                return
            }

            do {
                let results = try await service.search(query)

                guard !Task.isCancelled else { return }

                state.results = results
                state.isLoading = false
                state.message = results.isEmpty ? "No results" : "\(results.count) results"
            } catch {
                guard !Task.isCancelled else { return }

                state.results = []
                state.isLoading = false
                state.message = "Search failed"
            }
        }
    }
}

@ViewWith(state: SearchState.self, action: SearchAction.self)
struct SearchView: View {

    @ObservedObject
    var viewModel: AnyViewModel<SearchState, SearchAction>

    init(_ viewModel: AnyViewModel<SearchState, SearchAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField(
                    "Search",
                    text: viewModel.binding(\.query, onChange: SearchAction.queryChanged)
                )

                Button("Clear") {
                    viewModel.trigger(action: .clear)
                }

                Button("Search") {
                    viewModel.trigger(action: .search)
                }
                .disabled(viewModel.isLoading)
            }

            if viewModel.isLoading {
                ProgressView()
            }

            Text(viewModel.message)

            List(viewModel.results, id: \.self) { result in
                Text(result)
            }
        }
        .padding()
    }
}
```

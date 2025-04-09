// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 `ViewWith` is a macro that generates a SwiftUI view that conforms to the `ViewProtocol`.
 It automatically injects a `ViewModel` and establishes the necessary bindings between the view and its state and actions.

 - Usage:
    Apply the `@ViewWith` macro to a SwiftUI view struct to create a new view that requires state and action types as generics.

 - Parameters:
    - `state`: A type parameter representing the state type conforming to `StateProtocol`.
    - `action`: A type parameter representing the action type conforming to `ActionProtocol`.

 - Example:

    ```swift
    @ViewWith(state: MyState.self, action: MyAction.self)
    struct MyView: View {

        @ObserverObject var viewModel: AnyViewModel<S, A>

        init(_ viewModel: AnyViewModel<S, A>) {
            self.viewModel = viewModel
        }

        var body: some View {
            // Your view implementation here
        }
    }
    ```

 - How it Works:
    The `ViewWith` macro generates a conforming SwiftUI view struct that integrates with a `ViewModel` managing the specified state and actions.

 - Requirements:
    - The `state` type must conform to `StateProtocol`.
    - The `action` type must conform to `ActionProtocol`.

 - Limitations:
    - The macro assumes that the `ViewModel` used conforms to the `ViewModelProtocol` with appropriate state and action types.
    - May not support complex nested views or custom view hierarchies without further customization.

 - Supported Types:
    Any view that needs to bind with a state and action for MVVM architecture, where both types conform to the specified protocols.
 */
@attached(extension, conformances: ViewProtocol)
@attached(member, names: named(init))
public macro ViewWith<S: StateProtocol, A: ActionProtocol>(state: S.Type, action: A.Type) = #externalMacro(module: "DufapMacros", type: "ViewStateActionMacro")

/**
 `ViewModel` is a macro that generates a ViewModel that conforms to the `ViewModelProtocol`.
 It automatically synthesizes the necessary state management and action handling logic.

 - Usage:
    Apply the `@ViewModel` macro to a class or struct to create a ViewModel that manages a specific state and actions.

 - Example:

    ```swift
    @ViewModel
    class MyViewModel {
        // Your logic implementation here
    }
    ```

 - How it Works:
    The `ViewModel` macro generates a ViewModel with an `updateStateQueue` for managing state updates in a thread-safe manner. It ensures that the ViewModel automatically conforms to `ProtectedStateHolder` and `ObservableObject`.

 - Requirements:
    - The generated ViewModel must have a state conforming to `StateProtocol`.
    - The actions must conform to `ActionProtocol`.

 - Supported Types:
    Any class or struct intended to serve as a ViewModel within an MVVM architecture, where state and action types conform to their respective protocols.
 */
@attached(extension, conformances: ViewModelProtocol)
@attached(member, names: named(updateStateQueue))
@attached(memberAttribute)
public macro ViewModel() = #externalMacro(module: "DufapMacros", type: "ViewModelMacro")


// 
@attached(extension, conformances: CancelableAction, names: named(cancelID))
public macro CancelableAction() = #externalMacro(module: "DufapMacros", type: "CancelableActionMacro")

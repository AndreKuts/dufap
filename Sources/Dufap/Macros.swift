//  Copyright 2025 Andrew Rew
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


/**
 `ViewWith` is a macro that generates a SwiftUI view that conforms to the ``ViewProtocol``.
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
    - The `state` type must conform to ``StateProtocol``.
    - The `action` type must conform to ``ActionProtocol``.

 - Limitations:
    - The macro assumes that the `ViewModel` used conforms to the ``ViewModelProtocol`` with appropriate state and action types.
    - May not support complex nested views or custom view hierarchies without further customization.

 - Supported Types:
    Any view that needs to bind with a state and action for MVVM architecture, where both types conform to the specified protocols.
 */
@attached(extension, conformances: ViewProtocol)
@attached(member, names: named(init))
public macro ViewWith<S: StateProtocol, A: ActionProtocol>(state: S.Type, action: A.Type) = #externalMacro(module: "DufapMacros", type: "ViewStateActionMacro")


/**
 `ViewModel` is a macro that generates a ViewModel that conforms to the ``ViewModelProtocol``.
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
    - The `ViewModel` macro generates a ViewModel that automatically conforms to `ObservableObject`.

 - Requirements:
    - The generated ViewModel must have a state conforming to ``StateProtocol``.
    - The actions must conform to ``ActionProtocol``.

 - Supported Types:
    Any class or struct intended to serve as a ViewModel within an MVVM architecture, where state and action types conform to their respective protocols.
 */
@attached(extension, conformances: ViewModelProtocol)
@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro ViewModel<A: ActionProtocol>(action: A.Type) = #externalMacro(module: "DufapMacros", type: "ViewModelMacro")


/**
 `@Action` is a custom macro that transforms an enum into a set of actions conforming to ``ActionProtocol``.

 This macro:
 - Adds protocol conformance to ``ActionProtocol``
 - Injects new members (e.g., derived ``SyncAction`` or ``AsyncAction`` enums)
 - Helps with unidirectional data flow by modelling actions

 Internally, it uses annotations such as `triggerMode` to determine whether to generate synchronous or asynchronous variants.
*/
@attached(extension, conformances: ActionProtocol)
@attached(member, names: arbitrary)
public macro Action() = #externalMacro(module: "DufapMacros", type: "ActionMacro")


/**
 `@Pathable` enhances an enum (typically representing a navigation path) with identity and hashing capabilities.

 This macro:
 - Conforms the enum to `Hashable`, `Equatable`, and `Identifiable`
 - Injects an `index` property to reflect the enum case order
 - Provides an `id` property based on the index
 - Implements `hash(into:)` and `==` using the index

 It's particularly useful when enums are used in SwiftUI navigation stacks or `ForEach` constructs.
*/
@attached(extension, conformances: Hashable, Equatable, Identifiable, names: named(index), named(id), named(hash(into:)), named(==))
public macro Pathable() = #externalMacro(module: "DufapMacros", type: "PathMacro")

//
//  Copyright 2025 Andrew Kuts
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

import SwiftUI

/**
 `ViewProtocol` defines a contract for SwiftUI views in the MVVM architecture.
 It ensures that each conforming view has a ViewModel that follows the ``AnyViewModel`` pattern, providing a clear separation between the view and its underlying state and actions.

 - Requirements:
    - `S`: The state type associated with the view, conforming to ``StateProtocol``.
    - `A`: The action type associated with the view, conforming to ``ActionProtocol``.
    - The view must have a ViewModel of type `AnyViewModel<State, Action>` to manage the state and trigger actions.

 - Conforms to:
    - `View`: The SwiftUI view protocol.
 */
public protocol ViewProtocol where Self: View {

    /// The type of state that the ViewModel manages, conforming to ``StateProtocol``.
    associatedtype S: StateProtocol

    /// The type of action that the ViewModel can trigger, conforming to ``ActionProtocol``.
    associatedtype A: ActionProtocol

    /// The ViewModel managing the state and actions of the view, encapsulated in an ``AnyViewModel``.
    var viewModel: AnyViewModel<S, A> { get }

    /**
     Initializes a view with an ``AnyViewModel`` managing its state and actions.

     - Parameters:
        - viewModel: The ``AnyViewModel`` instance managing the view's state and actions.
     */
    init(_ viewModel: AnyViewModel<S, A>)
}

public extension ViewProtocol {

    /**
     Convenience initializer to wrap a concrete ``ViewModelProtocol`` into an ``AnyViewModel``.

     - Parameters:
        - viewModel: A concrete ViewModel instance conforming to `ViewModelProtocol`.

     - Note:
        This allows views to be initialized directly with a `ViewModelProtocol`-conforming ViewModel, which is then wrapped into an `AnyViewModel` for type erasure.
     */
    @MainActor
    init<V: ViewModelProtocol>(viewModel: V) where V.A == A, V.S == S {
        self.init(AnyViewModel(viewModel))
    }
}

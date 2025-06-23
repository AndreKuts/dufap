//
//  ViewProtocol.swift
//  Dufap
//
//  Created by Andrew Kuts
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
    init<V: ViewModelProtocol>(viewModel: V) where V.A == A, V.S == S {
        self.init(AnyViewModel(viewModel))
    }
}

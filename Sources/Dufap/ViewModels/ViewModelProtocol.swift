//
//  ViewModelProtocol.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Combine

/**
 `ViewModelProtocol` defines the base structure for a ViewModel in the MVVM architecture.
 It inherits from `ProtectedStateHolder` to manage the state and `ObservableObject` to allow views to observe state changes.
 
 - Requirements:
    - A `S` state type conforming to `StateProtocol`, inherited from `ProtectedStateHolder`.
    - An `A` action type conforming to `ActionProtocol`, representing actions or events that can trigger changes in state.
    - A method to trigger actions that modify the ViewModel's state.
 
 - Inherits:
    - `ProtectedStateHolder`: Provides thread-safe state management.
    - `ObservableObject`: Enables automatic UI updates when the state changes.
 */
public protocol ViewModelProtocol: ProtectedStateHolder, ObservableObject where ObjectWillChangePublisher.Output == Void {

    /// The type of actions that the ViewModel can handle, conforming to `ActionProtocol`.
    associatedtype A: ActionProtocol

    /// Publisher for State
    var statePublisher: Published<S>.Publisher { get }

    /// Cancellable Bag
    var bag: CancellableBag { get }

    /**
     Triggers a specified action that should modify the ViewModel's state.

     - Parameters:
        - action: The action to be triggered, conforming to `Action`.

     - Note:
        This function should handle the logic for how an action modifies the ViewModel's state.
     */
    func trigger(action: A.SA)

    func triggerAsync(action: A.AA) async

}


// Extend the Never type to conform to both AsyncActionProtocol and SyncActionProtocol
// This allows Never to be used in contexts where these protocols are expected, but it won't actually perform any actions.
extension Never: AsyncActionProtocol, SyncActionProtocol {

    // The initializer returns nil because Never cannot be initialized from any ActionProtocol
    // It signifies that there is no meaningful action associated with this type.
    public init?(from original: any ActionProtocol) {
        nil
    }

    // Define a cancelID property, which returns a constant string "never".
    // This ensures that even though Never is used as a placeholder, it still conforms to the protocol's requirements.
    public var cancelID: String {
        "never"
    }
}


// Define a ViewModelProtocol extension with a constraint that the associated action type (A.AA) is Never.
// This is for async actions that are effectively "no-ops," meaning no actual asynchronous action is triggered.
public extension ViewModelProtocol where A.AA == Never {

    // The function `triggerAsync` takes a Never action but doesn't actually do anything.
    // It's used for situations where no asynchronous action is expected, providing an empty async trigger.
    func triggerAsync(action: Never) async { }
}


// Define a ViewModelProtocol extension where the associated action type (A.SA) is Never.
// This is for synchronous actions that are also "no-ops" and don't perform any action.
public extension ViewModelProtocol where A.SA == Never {

    // The function `trigger` takes a Never action and doesn't perform any operation.
    // It acts as a placeholder for situations where no action is needed or available.
    func trigger(action: A.SA) { }
}

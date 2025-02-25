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

    var bag: CancellableBag<String> { get }

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

extension Never: AsyncActionProtocol { }
public extension ViewModelProtocol where A.AA == Never {
    func triggerAsync(action: Never) async { }
}

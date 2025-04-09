import Combine
import Foundation

/**
 `ActionProtocol` is a marker protocol for defining actions within the MVVM architecture.
 Actions represent user inputs or events that affect the application's state.
 */
public protocol ActionProtocol {
    var trigerMode: TriggerMode { get }
}

extension ActionProtocol {
    public var trigerMode: TriggerMode { .sync }
}

@frozen
public enum TriggerMode {
    case sync
    case async
}

/**
 `StateProtocol` is a marker protocol for defining state within the MVVM architecture.
 States represent the current condition or data of the ViewModel.
 */
public protocol StateProtocol { }

@dynamicMemberLookup
/**
 `AnyViewModel` is a type-erased wrapper around any object conforming to the `ViewModelProtocol`.
 It helps to abstract away specific implementations of `ViewModelProtocol` and provides a standard interface for interaction.
 
 - Generic Parameters:
    - `S`: The state type of the ViewModel, conforming to `StateProtocol`.
    - `A`: The action type of the ViewModel, conforming to `ActionProtocol`.
 
 - Inherits:
    - `ObservableObject`: To enable automatic view updates when the `state` changes.
 */
open class AnyViewModel<S: StateProtocol, A: ActionProtocol>: ObservableObject {

    /// A closure that returns a publisher to notify about changes to the ViewModel.
    private let wrappedObjectWillChange: () -> AnyPublisher<Void, Never>

    /// A closure that returns the current state of the ViewModel.
    private let wrappedState: () -> S

    /// A closure that triggers an action on the ViewModel.
    private let wrappedTrigger: (A) -> Void

    /// Publisher to notify views about changes, using Combine's `objectWillChange`.
    public var objectWillChange: AnyPublisher<Void, Never> { wrappedObjectWillChange() }

    /// Current state of the ViewModel.
    public var state: S { wrappedState() }

    /**
     Initializes an `AnyViewModel` with a given concrete ViewModel that conforms to `ViewModelProtocol`.

     - Parameters:
        - viewModel: A concrete ViewModel instance conforming to `ViewModelProtocol`.

     - Requires:
        - The `viewModel` must have matching `S`state  and `A` action types.
     */
    public init<V: ViewModelProtocol>(_ viewModel: V) where V.S == S, V.A == A {
        self.wrappedObjectWillChange = {
            viewModel
                .objectWillChange
                .receive(on: OperationQueue.main)
                .eraseToAnyPublisher()
        }
        self.wrappedState = { viewModel.state }
        self.wrappedTrigger = viewModel.trigger
    }

    /**
     Triggers an action on the ViewModel.

     - Parameters:
        - action: The action to be triggered, conforming to `Action`.
     */
    public func trigger(action: A) {
        wrappedTrigger(action)
    }

    /**
     Provides dynamic member lookup, allowing access to properties of the `state` using dot notation.

     - Parameters:
        - keyPath: The keyPath to the property in the `State`.

     - Returns: The value of the property specified by the keyPath in the `State`.
     */
    public subscript<Value>(dynamicMember keyPath: KeyPath<S, Value>) -> Value {
        state[keyPath: keyPath]
    }
}

extension AnyViewModel: Identifiable where S: Identifiable {
    /// The unique identifier for the ViewModel, derived from the state's identifier.
    public var id: S.ID { state.id }
}

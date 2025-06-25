//
//  AnyViewModel.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Combine
import Foundation
import SwiftUI

/**
 A type-erased, observable view model that wraps any concrete `ViewModelProtocol`
 and exposes its interface through a unified `ObservableObject` API.

 This view model is generic over:

 - `S`: The state type conforming to ``StateProtocol``.
 - `A`: The action type conforming to ``ActionProtocol``.

 Features:
 - Dynamic member lookup support for state access.
 - Transparent forwarding of `objectWillChange` publisher.
 - Deduplicated state synchronization using Combine.
 - Trigger forwarding for both sync and async actions.
 */
@dynamicMemberLookup
public class AnyViewModel<S: StateProtocol, A: ActionProtocol>: ObservableObject {

    /// A closure that forwards sync actions to the underlying concrete view model.
    private let wrappedTrigger: (A.SA) -> Void

    /// A closure that forwards async actions to the underlying concrete view model.
    private let wrappedTriggerAsync: (A.AA) async -> Void

    /// A cancellable bag used for storing Combine subscriptions with identifier support.
    private var bag: CancellableBag

    /// A publisher that notifies SwiftUI views when changes occur.
    @Published public private(set) var state: S

    /// Initializes the type-erased view model by wrapping a concrete ``ViewModelProtocol`` instance.
    ///
    /// - Parameter viewModel: The concrete view model to wrap. Must match the expected `S` and `A` types.
    @MainActor
    public init<V: ViewModelProtocol>(_ viewModel: V) where V.S == S, V.A == A {
        self.state = viewModel.state
        self.wrappedTrigger = viewModel.trigger
        self.wrappedTriggerAsync = viewModel.triggerAsync
        self.bag = viewModel.bag

        viewModel
            .statePublisher
            .sink { [weak self] newState in
                guard let self, self.state != newState else {
                    return
                }
                self.state = newState
            }
            .store(in: bag, as: "update_state")
    }

    deinit {
        bag.cancelAll()
    }

    /**
     Triggers the given action on the underlying ViewModel.

     This method first notifies the ``ActionPluginRegistry`` that an action is about to be triggered.
     It attempts to convert the provided action into a synchronous or asynchronous variant.
     Depending on the result, it invokes the appropriate trigger method and notifies the registry after completion.

     - Parameters:
        - action: The action to trigger.
        - pluginRegistry: The plugin registry used to observe action lifecycle events. Defaults to `ActionPluginRegistry.shared`.

     - Note:
        - This method supports dependency injection of `pluginRegistry` to improve testability and avoid repeated access to the shared singleton.
        - If the action cannot be resolved to a known sync or async type, an assertion failure is raised.
     */
    public func trigger(action: A, pluginRegistry: ActionPluginRegistry = .shared) {

        pluginRegistry.willTrigger(action: action)

        if let syncAction = A.SA(from: action) {
            wrappedTrigger(syncAction)
            pluginRegistry.didTrigger(action: action)
        } else

        if let asyncAction = A.AA(from: action) {
            Task {
                await wrappedTriggerAsync(asyncAction)
                pluginRegistry.didTrigger(action: action)
            }
            .store(in: bag, as: action.cancelID)

        } else {
            assertionFailure("Unhandled action type: \(action)")
        }
    }

    /**
     Provides dynamic member lookup, allowing access to properties of the `state` using dot notation.

     - Parameter keyPath: The keyPath to the property in the `State`.
     - Returns: The value of the property specified by the keyPath.
     */
    public subscript<Value>(dynamicMember keyPath: KeyPath<S, Value>) -> Value {
        state[keyPath: keyPath]
    }

    /**
     Creates a read-only SwiftUI Binding to a value in the current state.

     This is primarily useful for views that display state values but do not allow user edits.
     The setter does nothing, preserving one-way data flow from the view model to the view.

     - Parameter keyPath: A writable key path to a value within the state.
     - Returns: A SwiftUI Binding with a functional getter and a no-op setter.
     */
    public func binding<Value>(_ keyPath: WritableKeyPath<S, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { _ in }
        )
    }

    /**
     Creates a two-way SwiftUI Binding to a value in the current state,
     and triggers an action whenever the value is updated via the UI.

     This enables editable views (e.g. TextField, Toggle) to remain declarative
     while maintaining unidirectional data flow through action dispatching.

     - Parameters:
        - keyPath: A writable key path to a value within the state.
        - onChange: A closure that produces an action to trigger when the value changes.
     - Returns: A SwiftUI Binding that reads from state and triggers actions on user updates.
     */
    public func binding<Value>(_ keyPath: WritableKeyPath<S, Value>, onChange: @escaping (Value) -> A) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.trigger(action: onChange($0)) }
        )
    }
}


extension AnyViewModel: @preconcurrency Identifiable where S: Identifiable {

    /// The unique identifier for the ViewModel, derived from the state's identifier.
    public var id: S.ID { state.id }
}

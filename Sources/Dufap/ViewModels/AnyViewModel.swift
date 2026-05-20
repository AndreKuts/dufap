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

    private let wrappedTrigger: (A.SA) -> Void
    private let wrappedTriggerAsync: @MainActor (A.AA) async -> Void
    private let bag: CancellableBag
    private let lifecycleQueue = DispatchQueue(label: "com.dufap.any_view_model.lifecycle")
    private var runningAsyncActions: [String: (token: UUID, action: A)] = [:]

    /// A publisher that notifies SwiftUI views when changes occur.
    @Published public private(set) var state: S

    /// Initializes the type-erased view model by wrapping a concrete ``ViewModelProtocol`` instance.
    ///
    /// - Parameter viewModel: The concrete view model to wrap. Must match the expected `S` and `A` types.
    public init<V: ViewModelProtocol>(_ viewModel: V) where V.S == S, V.A == A {
        self.state = viewModel.state
        self.wrappedTrigger = viewModel.trigger
        self.wrappedTriggerAsync = viewModel.triggerAsync
        self.bag = viewModel.bag

        viewModel
            .statePublisher
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newState in
                self?.publishStateOnMain(newState)
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

     - Note:
     - If the action cannot be resolved to a known sync or async type, an assertion failure is raised.
     */
    public func trigger(action: A) {

        let plugins = ActionPluginRegistry.allIfNotEmpty()
        sendLifecycle(.willTrigger, action: action, to: plugins)

        if let syncAction = A.SA(from: action) {
            triggerSyncAction(syncAction, originalAction: action, plugins: plugins)
        } else if let asyncAction = A.AA(from: action) {
            triggerAsyncAction(asyncAction, originalAction: action, plugins: plugins)
        } else {
            handleUnhandledAction(action, plugins: plugins)
        }
    }

    private func triggerSyncAction(
        _ syncAction: A.SA,
        originalAction action: A,
        plugins: [ActionPlugin]?
    ) {
        if Thread.isMainThread {
            wrappedTrigger(syncAction)
            sendLifecycle(.didTrigger, action: action, to: plugins)
        } else {
            DispatchQueue.main.async {
                self.wrappedTrigger(syncAction)
                self.sendLifecycle(.didTrigger, action: action, to: plugins)
            }
        }
    }

    private func triggerAsyncAction(
        _ asyncAction: A.AA,
        originalAction action: A,
        plugins: [ActionPlugin]?
    ) {
        let token = UUID()
        let cancelID = action.cancelID

        sendCancellationForReplacedAction(
            action,
            token: token,
            cancelID: cancelID,
            plugins: plugins
        )

        Task { @MainActor in
            await wrappedTriggerAsync(asyncAction)

            guard removeRunningAction(cancelID: cancelID, token: token) else { return }

            if Task.isCancelled {
                sendLifecycle(.didCancel, action: action, to: plugins)
            } else {
                sendLifecycle(.didTrigger, action: action, to: plugins)
            }
        }
        .store(in: bag, as: cancelID)
    }

    private func sendCancellationForReplacedAction(
        _ action: A,
        token: UUID,
        cancelID: String,
        plugins: [ActionPlugin]?
    ) {
        let previousAction = replaceRunningAction(action, token: token, cancelID: cancelID)
        let didCancelStoredTask = bag.cancel(id: cancelID) != nil

        if let cancelledAction = previousAction ?? (didCancelStoredTask ? action : nil) {
            sendLifecycle(.didCancel, action: cancelledAction, to: plugins)
        }
    }

    private func handleUnhandledAction(_ action: A, plugins: [ActionPlugin]?) {
        sendLifecycle(
            .didFail,
            action: action,
            to: plugins,
            errorDescription: "Unhandled action type"
        )
        assertionFailure("Unhandled action type: \(action)")
    }

    private func replaceRunningAction(_ action: A, token: UUID, cancelID: String) -> A? {
        var previousAction: A?

        lifecycleQueue.sync {
            previousAction = runningAsyncActions[cancelID]?.action
            runningAsyncActions[cancelID] = (token, action)
        }

        return previousAction
    }

    private func removeRunningAction(cancelID: String, token: UUID) -> Bool {
        var didRemove = false

        lifecycleQueue.sync {
            guard runningAsyncActions[cancelID]?.token == token else { return }

            runningAsyncActions[cancelID] = nil
            didRemove = true
        }

        return didRemove
    }

    private func publishStateOnMain(_ newState: S) {
        if Thread.isMainThread {
            state = newState
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.state = newState
            }
        }
    }

    private func sendLifecycle(
        _ phase: ActionLifecyclePhase,
        action: A,
        to plugins: [ActionPlugin]?,
        errorDescription: String? = nil
    ) {
        ActionPluginRegistry.send(
            ActionLifecycleEvent(
                phase: phase,
                action: action,
                errorDescription: errorDescription
            ),
            to: plugins
        )
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
     Creates a two-way SwiftUI `Binding` to a value in the current state,
     and triggers an action whenever the value is updated via the UI.

     This allows editable SwiftUI views (e.g., `TextField`, `SecureField`, `Toggle`)
     to remain declarative while maintaining unidirectional data flow
     through action dispatching.

     The `Value` type must conform to `Equatable` to prevent duplicate actions
     when the UI sets the same value multiple times (common in `TextField`/`SecureField`).

     - Parameters:
     - keyPath: A writable key path to a value within the state.
     - onChange: A closure that produces an action to trigger when the value changes.
     - Returns: A SwiftUI `Binding` that reads from state and triggers actions
     on user updates, while avoiding duplicate actions for unchanged values.
     */
    public func binding<Value: Equatable>(
        _ keyPath: WritableKeyPath<S, Value>,
        onChange: @escaping (Value) -> A
    ) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in
                // Only trigger action if the new value differs from current state
                if self.state[keyPath: keyPath] != newValue {
                    self.trigger(action: onChange(newValue))
                }
            }
        )
    }
}


extension AnyViewModel: Identifiable where S: Identifiable {

    /// The unique identifier for the ViewModel, derived from the state's identifier.
    public var id: S.ID { state.id }
}

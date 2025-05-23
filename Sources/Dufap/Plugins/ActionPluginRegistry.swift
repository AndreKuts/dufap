//
//  ActionPluginRegistry.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation


/**
 `ActionPlugin` is a protocol for observing the lifecycle of actions.

 Implementers can hook into the triggering process to log, monitor, or modify behavior.
 */
public protocol ActionPlugin {

    /**
     Called immediately before an action is triggered.
     - Parameter action: The action about to be triggered.
     */
    func willTrigger(action: any ActionProtocol)

    /**
     Called immediately after an action has been triggered.
     - Parameter action: The action that was triggered.
     */
    func didTrigger(action: any ActionProtocol)
}


/**
 `ActionPluginRegistry` is a global, thread-safe container for registering and notifying `ActionPlugin`s.

 It enables cross-cutting concerns like logging, metrics, and debugging
 to be applied to all actions without modifying core logic.
 */
public final class ActionPluginRegistry {

    /// Shared singleton instance of the registry.
    public static let shared = ActionPluginRegistry()

    /// Storage for registered plugins.
    private var storage: [any ActionPlugin] = []

    /// A concurrent dispatch queue to ensure thread-safe access to plugins.
    private let queue = DispatchQueue(label: "com.dufap.action_plugin_registry.queue", attributes: .concurrent)

    private init() { }

    /**
     Attaches a new plugin to the registry.

     - Parameter plugin: A plugin conforming to `ActionPlugin`.
     */
    public func attach<M: ActionPlugin>(_ plugin: M) {
        queue.async(flags: .barrier) { [weak self] in
            self?.storage.append(plugin)
        }
    }

    /**
     Notifies all registered plugins that an action is about to be triggered.

     - Parameter action: The action that is about to be triggered.
     */
    public func willTrigger(action: any ActionProtocol) {
        queue.sync {
            for plugin in storage {
                plugin.willTrigger(action: action)
            }
        }
    }

    /**
     Notifies all registered plugins that an action has been triggered.

     - Parameter action: The action that was triggered.
     */
    func didTrigger(action: any ActionProtocol) {
        queue.sync {
            for plugin in storage {
                plugin.didTrigger(action: action)
            }
        }
    }
}

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

import Foundation

/**
 `ActionPlugin` is a protocol for observing the lifecycle of actions.

 Implementers can hook into the triggering process to log, monitor, or modify behaviour.
 */
public protocol DufapPlugin {
    func receive(_ event: ActionLifecycleEvent)
}

public protocol ActionPlugin: DufapPlugin {

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

    func didCancel(action: any ActionProtocol)

    func didFail(action: any ActionProtocol, errorDescription: String?)
}

public extension ActionPlugin {

    func receive(_ event: ActionLifecycleEvent) {
        switch event.phase {
        case .willTrigger:
            willTrigger(action: event.action)
        case .didTrigger:
            didTrigger(action: event.action)
        case .didCancel:
            didCancel(action: event.action)
        case .didFail:
            didFail(action: event.action, errorDescription: event.errorDescription)
        }
    }

    func didCancel(action: any ActionProtocol) { }

    func didFail(action: any ActionProtocol, errorDescription: String?) { }
}


/// A thread-safe global registry for managing `ActionPlugin` instances.
public enum ActionPluginRegistry {

    private static var plugins = [ActionPlugin]()
    private static let queue = DispatchQueue(label: "ActionPluginRegistry.queue", attributes: .concurrent)

    /// Registers a plugin in a thread-safe way.
    /// - Parameter plugin: The `ActionPlugin` to add to the registry.
    public static func register(_ plugin: ActionPlugin) {
        queue.sync(flags: .barrier) {
            plugins.append(plugin)
        }
    }

    /// Returns a snapshot of all registered plugins.
    /// - Returns: A thread-safe copy of the plugin array.
    public static func all() -> [ActionPlugin] {
        queue.sync {
            plugins
        }
    }

    /// Returns registered plugins, or `nil` when the registry is empty.
    /// Use this in hot paths to avoid plugin lifecycle work when no plugins are installed.
    public static func allIfNotEmpty() -> [ActionPlugin]? {
        queue.sync {
            plugins.isEmpty ? nil : plugins
        }
    }

    public static func removeAll() {
        queue.sync(flags: .barrier) {
            plugins.removeAll()
        }
    }

    public static func send(_ event: ActionLifecycleEvent, to plugins: [ActionPlugin]?) {
        plugins?.forEach { $0.receive(event) }
    }
}

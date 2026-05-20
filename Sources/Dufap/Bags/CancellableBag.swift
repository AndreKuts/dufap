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

/// A deterministic cancellation store for async tasks.
public actor CancellationStore {

    private var tasks: [String: Task<Void, Never>] = [:]

    public init() {}

    public func add(_ task: Task<Void, Never>, id: String) {
        tasks[id]?.cancel()
        tasks[id] = task
    }

    public func cancel(id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
    }

    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
}

/// A thread-safe cancellation container that manages cancellable resources by ID.
/// Supports cancellation of `AnyCancellable`, `NSKeyValueObservation`, custom ``CancellableTask``, and others.
open class CancellableBag {

    private var bag: [AnyHashable: Any] = [:]
    private let queue = DispatchQueue(label: "com.dufap.cancellable_bag.queue", attributes: .concurrent)

    public init() {}

    /**
     Cancels and removes a cancellable item associated with the given ID, if it exists.

     - Parameter id: The identifier of the cancellable item.
     - Returns: The removed item, or `nil` if not found.
     */
    @discardableResult
    public func cancel(id: AnyHashable) -> Any? {
        var value: Any?

        queue.sync(flags: .barrier) {
            value = bag.removeValue(forKey: id)
        }

        cancel(value)

        return value
    }

    /// Cancels and removes all stored cancellable items.
    public func cancelAll() {
        var values: [Any] = []

        queue.sync(flags: .barrier) {
            values = Array(bag.values)
            bag.removeAll()
        }

        values.forEach(cancel)
    }

    /**
     Adds a cancellable item to the bag, replacing any existing item with the same ID.

     - Parameters:
        - id: Unique identifier for the cancellable item.
        - any: The cancellable object to store.
     */
    public func add(id: AnyHashable, _ any: Any?) {
        var previous: Any?

        queue.sync(flags: .barrier) {
            previous = bag.removeValue(forKey: id)
            bag[id] = any
        }

        cancel(previous)
    }

    private func cancel(_ value: Any?) {
        switch value {

        case let cancellable as AnyCancellable:
            cancellable.cancel()

        case let observer as NSKeyValueObservation:
            observer.invalidate()

        case let task as CancellableTask:
            task.cancel()

        default:
            break
        }
    }
}

/// A wrapper around `Task` to allow manual cancellation and storage in a ``CancellableBag``.
public class CancellableTask {

    private var task: Task<Void, Never>?
    private let lock = NSLock()

    /**
     Creates and starts a cancellable task.

     - Parameter operation: The async operation to run.
     - Returns: A ``CancellableTask`` instance that can be stored or cancelled.
     */
    public static func run(_ operation: @escaping @Sendable () async -> Void) -> CancellableTask {
        return CancellableTask(Task {
            await operation()
        })
    }

    public init(_ task: Task<Void, Never>) {
        self.task = task
    }

    /// Cancels the task and removes the reference.
    public func cancel() {
        lock.lock()
        let task = task
        self.task = nil
        lock.unlock()

        task?.cancel()
    }
}


public extension Task where Success == Void, Failure == Never {

    /// Stores a `Task` in the provided ``CancellableBag`` using the given identifier.
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, CancellableTask(self))
    }
}


public extension AnyCancellable {

    /// Stores an `AnyCancellable` in the provided ``CancellableBag`` using the given identifier.
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}


public extension NSKeyValueObservation {

    /// Stores an `NSKeyValueObservation` in the provided ``CancellableBag`` using the given identifier.
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}


public extension NSObjectProtocol {

    /// Stores an `NSObjectProtocol` (typically a Notification observer) in the ``CancellableBag`` using the given identifier.
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}

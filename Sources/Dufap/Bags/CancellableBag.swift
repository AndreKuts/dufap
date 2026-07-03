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

/// A resource that can be torn down and stored in a ``CancellableBag``.
/// Conforming types (`AnyCancellable`, `NSKeyValueObservation`, ``CancellableTask``,
/// notification tokens) replace the old `Any` + type-switch storage with a
/// compiler-checked contract.
public protocol DufapCancellable {
    func dufapCancel()
}

/// A thread-safe cancellation container that stores ``DufapCancellable`` resources by ID.
/// `@unchecked Sendable`: all storage access is serialized by the internal serial queue.
open class CancellableBag: @unchecked Sendable {

    private var bag: [AnyHashable: any DufapCancellable] = [:]
    private let queue = DispatchQueue(label: "com.dufap.cancellable_bag.queue")

    public init() {}

    /**
     Cancels and removes a cancellable item associated with the given ID, if it exists.

     - Parameter id: The identifier of the cancellable item.
     - Returns: The removed item, or `nil` if not found.
     */
    @discardableResult
    public func cancel(id: AnyHashable) -> (any DufapCancellable)? {
        let value = queue.sync { bag.removeValue(forKey: id) }
        value?.dufapCancel()
        return value
    }

    /// Cancels and removes all stored cancellable items.
    public func cancelAll() {
        let values = queue.sync { () -> [any DufapCancellable] in
            let all = Array(bag.values)
            bag.removeAll()
            return all
        }
        values.forEach { $0.dufapCancel() }
    }

    /**
     Adds a cancellable item to the bag, replacing (and cancelling) any existing item with the same ID.

     - Parameters:
        - id: Unique identifier for the cancellable item.
        - item: The cancellable to store, or `nil` to just remove the existing one.
     */
    public func add(id: AnyHashable, _ item: (any DufapCancellable)?) {
        let previous = queue.sync { () -> (any DufapCancellable)? in
            let prev = bag.removeValue(forKey: id)
            bag[id] = item
            return prev
        }
        previous?.dufapCancel()
    }
}

/// A wrapper around `Task` to allow manual cancellation and storage in a ``CancellableBag``.
public final class CancellableTask: DufapCancellable {

    private var task: Task<Void, Never>?
    private let lock = NSLock()

    public func dufapCancel() { cancel() }

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


extension AnyCancellable: DufapCancellable {
    public func dufapCancel() { cancel() }
}

extension NSKeyValueObservation: DufapCancellable {
    public func dufapCancel() { invalidate() }
}

/// Wraps a NotificationCenter observer token so it is removed on cancel. The old
/// `Any`-based bag silently dropped these (its type-switch had no case for them);
/// this now actually tears the observer down.
private struct NotificationObserverCancellable: DufapCancellable {
    let observer: any NSObjectProtocol
    func dufapCancel() { NotificationCenter.default.removeObserver(observer) }
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
        bag.add(id: id, NotificationObserverCancellable(observer: self))
    }
}

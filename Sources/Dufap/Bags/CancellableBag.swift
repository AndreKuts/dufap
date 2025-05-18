//
//  CancellableBag.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Combine
import Foundation

/// A thread-safe cancellation container that manages cancellable resources by ID.
/// Supports cancellation of `AnyCancellable`, `NSKeyValueObservation`, custom `CancellableTask`, and others.
public final class CancellableBag {

    /// Internal dictionary holding cancellable items keyed by a unique identifier.
    private var bag: [AnyHashable: Any] = [:]

    /// A concurrent dispatch queue with barrier synchronization for thread-safe access.
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

        return value
    }

    /// Cancels and removes all stored cancellable items.
    public func cancelAll() {
        var keys: [AnyHashable] = []
        queue.sync {
            keys = Array(bag.keys)
        }
        keys.forEach { cancel(id: $0) }
    }

    /**
     Adds a cancellable item to the bag, replacing any existing item with the same ID.

     - Parameters:
        - id: Unique identifier for the cancellable item.
        - any: The cancellable object to store.
     */
    public func add(id: AnyHashable, _ any: Any?) {
        cancel(id: id)
        queue.async(flags: .barrier) {
            self.bag[id] = any
        }
    }
}

/// A wrapper around `Task` to allow manual cancellation and storage in a `CancellableBag`.
public final class CancellableTask {

    /// The underlying task to be managed.
    private var task: Task<Void, Never>?

    /**
     Creates and starts a cancellable task.

     - Parameter operation: The async operation to run.
     - Returns: A `CancellableTask` instance that can be stored or cancelled.
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
        task?.cancel()
        task = nil
    }
}

/// Stores a `Task` in the provided `CancellableBag` using the given identifier.
public extension Task where Success == Void, Failure == Never {
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, CancellableTask(self))
    }
}

/// Stores an `AnyCancellable` in the provided `CancellableBag` using the given identifier.
public extension AnyCancellable {
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}

/// Stores an `NSKeyValueObservation` in the provided `CancellableBag` using the given identifier.
public extension NSKeyValueObservation {
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}

/// Stores an `NSObjectProtocol` (typically a Notification observer) in the `CancellableBag` using the given identifier.
public extension NSObjectProtocol {
    func store(in bag: CancellableBag, as id: AnyHashable) {
        bag.add(id: id, self)
    }
}

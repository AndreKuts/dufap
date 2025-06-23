//
//  LockedValueBox.swift
//  Dufap
//
//  Created by Andrew Kuts on 2025-06-23.
//

import Foundation

/// A thread-safe container for holding a single value using a lock-based synchronization strategy.
public final class LockedValueBox<Value> {

    /// The stored value, protected by a lock.
    private var value: Value?

    /// Lock ensuring exclusive access to the value.
    private let lock = NSLock()

    public init() {}

    /// Stores or replaces the value.
    public func register(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }

    /// Retrieves the current value.
    public func resolve() -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

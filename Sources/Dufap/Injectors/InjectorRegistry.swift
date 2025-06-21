//
//  InjectorRegistry.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation

/// A global registry for holding references to `Injector` and `AsyncInjector` instances.
public enum InjectorRegistry {

    private static var injector: (any Injector)?
    private static var asyncInjector: (any AsyncInjector)?
    private static let lock = NSLock()

    /// Registers a synchronous injector instance.
    public static func register(_ injector: some Injector) {
        lock.lock()
        defer { lock.unlock() }
        self.injector = injector
    }

    /// Registers an asynchronous injector instance.
    public static func register(_ asyncInjector: some AsyncInjector) {
        lock.lock()
        defer { lock.unlock() }
        self.asyncInjector = asyncInjector
    }

    /// Resolves the current synchronous injector, if any.
    public static func resolve() -> (any Injector)? {
        lock.lock()
        defer { lock.unlock() }
        return injector
    }

    /// Resolves the current asynchronous injector, if any.
    public static func resolveAsync() -> (any AsyncInjector)? {
        lock.lock()
        defer { lock.unlock() }
        return asyncInjector
    }
}

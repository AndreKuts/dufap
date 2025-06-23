//
//  InjectorRegistry.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation

/// A global registry for holding references to ``Injector`` and ``AsyncInjector`` instances.
public enum InjectorRegistry {

    private static let syncRegistry = LockedValueBox<any Injector>()
    private static let asyncRegistry = LockedValueBox<any AsyncInjector>()

    /// Registers a synchronous injector instance.
    public static func register(_ injector: some Injector) {
        syncRegistry.register(injector)
    }

    /// Registers an asynchronous injector instance.
    public static func register(_ asyncInjector: some AsyncInjector) {
        asyncRegistry.register(asyncInjector)
    }

    /// Resolves the current synchronous injector, if any.
    public static func resolve() -> (any Injector)? {
        syncRegistry.resolve()
    }

    /// Resolves the current asynchronous injector, if any.
    public static func resolveAsync() -> (any AsyncInjector)? {
        asyncRegistry.resolve()
    }
}

//
//  Injected.swift
//  Dufap
//
//  Created by Andrew Kuts
//

/// Property wrapper for resolving and caching dependencies via an injector.
/// Injecting dependencies using ``InjectorRegistry``.
/// Supports both optional and non-optional types.
@propertyWrapper
public struct Injected<T> {

    /// Defines how the dependency should be injected (e.g., singleton, factory, or both).
    private let injectType: InjectingType

    /// Caches the resolved dependency to avoid repeated extraction.
    private var cached: T?

    /// Initializes the wrapper with an optional injection strategy. Default is `.both`.
    public init(_ injectType: InjectingType = .both) {
        self.injectType = injectType
    }

    /// Lazily resolves and returns the dependency. Caches the result after first use.
    public var wrappedValue: T {
        mutating get {
            if let cached {
                return cached
            }

            guard let injector = InjectorRegistry.resolve() else {
                fatalError("Injector not registered dependency of type \(T.self) using \(injectType) in InjectorRegistry")
            }

            // Handling for optional types
            if T.self is AnyOptional.Type {

                let value: T? = injector.extractOptional(from: injectType)

                if let value {
                    cached = value
                    return value
                } else {
                    fatalError("Failed to resolve optional dependency of type \(T.self) using \(injectType)")
                }
            }

            // Default type handling
            else {

                let value: T = injector.extract(from: injectType)
                cached = value

                return value
            }
        }
    }
}

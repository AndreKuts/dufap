//
//  AsyncInjector.swift
//  Dufap
//
//  Created by Andrew Kuts
//

/**
 `AsyncInjector` defines an interface for asynchronous dependency injection using Swift's `actor` model.
 
 This protocol enables safe injection, ejection, and retrieval of dependencies in concurrency contexts.
 
 - Note: The conforming type must have a `state` that holds dependency data and conforms to `StateProtocol`.
 */
public protocol AsyncInjector: AnyObject where S == InjectorState {

    /// The type representing the internal dependency storage, which must conform to `StateProtocol`.
    associatedtype S: StateProtocol

    /// The current dependency state used for storing and retrieving registered types.
    var state: S { get set }

    /**
     Asynchronously injects a dependency into the internal state using the specified injection type.

     - Parameters:
     - injectType: The strategy to use (e.g. `.singleton`, `.factory`, or `.both`).
     - builder: A closure that builds and returns the dependency instance.
     */
    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping () -> T) async

    /**
     Asynchronously removes a dependency from the internal state.

     - Parameters:
        - type: The type of the dependency to remove.
        - injectType: The strategy that determines which container(s) to remove the dependency from.
     */
    func eject<T>(type: T.Type, from injectType: InjectingType) async

    /**
     Asynchronously retrieves a dependency of the specified type.

     - Parameter injectType: The strategy to use for lookup (singleton, factory, or both).
     - Returns: The resolved dependency instance.
     - Precondition: The dependency must be registered; otherwise, the method will crash.
     */
    func extract<T>(from injectType: InjectingType) async -> T

    /**
     Asynchronously attempts to retrieve a dependency of the specified type, or throws if not found.
     
     - Parameter injectType: The strategy to use for lookup.
     - Returns: The resolved dependency instance.
     - Throws: `InjectorError.typeNotFound` if the dependency is not registered.
     */
    func extractThrows<T>(from injectType: InjectingType) async throws -> T
}

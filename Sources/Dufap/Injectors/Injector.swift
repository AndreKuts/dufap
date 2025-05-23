//
//  Injector.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation

/**
 The `Injector` protocol defines the interface for dependency injection.
 It extends the `ObservableObject` protocol, allowing this object to be used as an environment object.
 Additionally, it extends the `ProtectedStateHolder` protocol and provides methods to inject and extract dependencies safety..
 
 - Requires:
    - A state object that conforms to `InjectorState` and holds injected singletons and factories.
 */
public protocol Injector: ObservableObject, ProtectedStateHolder where S == InjectorState {

    /**
     Injects a dependency into the injector's state.

     - Parameters:
        - type: The type of injection (`singleton`, `factory`, or `both`).
        - builder: A closure that builds and returns an instance of the dependency.
     */
    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any Injector) -> T)

    /**
     Ejects a dependency from the injector's state.

     - Parameters:
        - type: Type of object to eject.
        - injectType: The type of injection (`singleton`, `factory`, or `both`).
     */
    func eject<T>(type: T.Type, from injectType: InjectingType)

    /**
     Extracts a dependency from the injector's state.

     - Parameters:
        - type: The type of injection (`singleton`, `factory`, or `both`).

     - Returns: The extracted dependency of type `T`.
     */
    func extract<T>(from injectType: InjectingType) -> T

    /**
     Extracts a dependency from the injector's state, throwing an error if it does not exist.

     - Parameters:
        - injectType: The type of injection (`singleton`, `factory`, or `both`).

     - Throws: `InjectorError.typeNotFound` if the dependency is not registered.

     - Returns: The extracted dependency of type `T`.
     */
    func extractThrows<T>(from injectType: InjectingType) throws -> T
}

public extension Injector {

    /**
     Extracts a dependency from the injector's state as factory.

     - Returns: The extracted dependency of type `T`.
     */
    func extract<T>() -> T {
        extract(from: .both)
    }

    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping (any Injector) -> T) {
        switch injectType {
        case .singleton:
            updateState { $0.singletons[ObjectIdentifier(T.self)] = builder(self) }
        case .factory:
            updateState { $0.factories[ObjectIdentifier(T.self)] = builder }
        case .both:
            updateState {
                $0.singletons[ObjectIdentifier(T.self)] = builder(self)
                $0.factories[ObjectIdentifier(T.self)] = builder
            }
        }
    }

    func eject<T>(type: T.Type, from injectType: InjectingType) {
        switch injectType {
        case .singleton:
            updateState { $0.singletons.removeValue(forKey: ObjectIdentifier(T.self))}
        case .factory:
            updateState { $0.factories.removeValue(forKey: ObjectIdentifier(T.self))}
        case .both:
            updateState {
                $0.singletons.removeValue(forKey: ObjectIdentifier(T.self))
                $0.factories.removeValue(forKey: ObjectIdentifier(T.self))
            }
        }
    }

    func extractThrows<T>(from injectType: InjectingType) throws -> T {
        switch injectType {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? (any Injector) -> T {
                return factory(self)
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? (any Injector) -> T {
                return factory(self)
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }

    func extract<T>(from injectType: InjectingType) -> T {
        switch injectType {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                fatalError("Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? (any Injector) -> T {
                return factory(self)
            } else {
                fatalError("Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? (any Injector) -> T {
                return factory(self)
            } else {
                fatalError("Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }
}

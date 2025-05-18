//
//  AsyncDependencyInjector.swift
//  Dufap
//
//  Created by Andrew Kuts
//

public actor AsyncDependencyInjector: @preconcurrency AsyncInjector {

    public var state: InjectorState

    public init() {
        self.state = InjectorState()
    }

    func extract<T>() -> T {
        extract(from: .both)
    }

    public func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping () -> T) {
        switch injectType {

        case .singleton:
            state.singletons[ObjectIdentifier(T.self)] = builder()

        case .factory:
            state.factories[ObjectIdentifier(T.self)] = builder

        case .both:
            state.singletons[ObjectIdentifier(T.self)] = builder()
            state.factories[ObjectIdentifier(T.self)] = builder
        }
    }

    public func eject<T>(type: T.Type, from injectType: InjectingType) {
        switch injectType {

        case .singleton:
            state.singletons.removeValue(forKey: ObjectIdentifier(T.self))

        case .factory:
            state.factories.removeValue(forKey: ObjectIdentifier(T.self))

        case .both:
            state.singletons.removeValue(forKey: ObjectIdentifier(T.self))
            state.factories.removeValue(forKey: ObjectIdentifier(T.self))

        }
    }

    public func extract<T>(from injectType: InjectingType) -> T {
        switch injectType {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                fatalError("Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                fatalError("Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                fatalError("Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }

    public func extractThrows<T>(from injectType: InjectingType) throws -> T {
        switch injectType {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton for an unregistered type: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a factory for an unregistered type: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                throw InjectorError.typeNotFound(message: "Error: Unable to extract type as a singleton or factory for an unregistered type: \(T.self)")
            }
        }
    }
}

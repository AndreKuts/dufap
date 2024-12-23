import Foundation

/**
 `DependencyInjector` is responsible for managing dependency injection within the application.
 It implements the `Injector` protocol and provides thread-safe mechanisms to manage and inject dependencies using `DispatchQueue`.
 */
public class DependencyInjector: Injector {

    /// Queue for safely updating the state
    public let updateStateQueue = DispatchQueue(label: "com.app.dependencies.injector")

    /// Current state of the `DependencyInjector`, holding singletons and factories
    public var state: InjectorState

    /// Initializes a new `DependencyInjector` with an empty state
    public init() {
        self.state = InjectorState()
    }
}

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
    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping () -> T)

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

    func inject<T>(for injectType: InjectingType, typeBuilder builder: @escaping () -> T) {
        switch injectType {
        case .singleton:
            updateState { $0.singletons[ObjectIdentifier(T.self)] = builder() }
        case .factory:
            updateState { $0.factories[ObjectIdentifier(T.self)] = builder }
        case .both:
            updateState {
                $0.singletons[ObjectIdentifier(T.self)] = builder()
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

    func extract<T>(from injectType: InjectingType) -> T {
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
}

/// Error type thrown when a dependency is not found in the injector's state.
public enum InjectorError: Error {
    case typeNotFound(message: String? = nil)
}

/// Defines the type of injection for a dependency
public enum InjectingType {

    /// Use an already created singleton object
    case singleton

    /// Create a new object each time it's requested
    case factory

    /// Check both singletons first, then factories if the object is not found in singletons
    case both
}

/**
 `InjectorState` holds the current state of the injector, storing both singleton objects and factory closures.
 */
public struct InjectorState: StateProtocol {

    /// Dictionary holding singleton objects
    public var singletons: [ObjectIdentifier: Any]

    /// Dictionary holding factory closures
    public var factories: [ObjectIdentifier: Any]

    /// Initializes a new `InjectorState` with optional pre-existing singletons and factories.
    public init(
        singletons: [ObjectIdentifier : Any] = [:],
        factories: [ObjectIdentifier : Any] = [:]
    ) {
        self.singletons = singletons
        self.factories = factories
    }
}

import Foundation

public class DefaultDependencyInjector: Injector {
    public let updateStateQueue = DispatchQueue(label: "com.app.dependencies.injector")
    public var state = InjectorState()
}

public protocol Injector: ProtectedStateHolder where State == InjectorState {
    func extract<T>(asType type: InjectingType) -> T
    func extractThrows<T>(asType type: InjectingType) throws -> T
    func inject<T>(asType type: InjectingType, typeBuilder: @escaping () -> T)
}

public extension Injector {

    func inject<T>(asType type: InjectingType, typeBuilder: @escaping () -> T) {
        switch type {
        case .singleton, .both:
            register(singleton: typeBuilder())
        case .factory:
            register(factory: typeBuilder)
        }
    }

    func extract<T>() -> T {
        extract(asType: .both)
    }

    func extractThrows<T>(asType type: InjectingType) throws -> T {
        switch type {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                throw InjectorError.typeNotFound(message: "Could not extract as singleton unregistered service: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                throw InjectorError.typeNotFound(message: "Could not extract as factory unregistered service: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                throw InjectorError.typeNotFound(message: "Could not extract as singleton or factory unregistered service: \(T.self)")
            }
        }
    }

    func extract<T>(asType type: InjectingType) -> T {
        switch type {
        case .singleton:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else {
                fatalError("Could not extract as singleton unregistered service: \(T.self)")
            }

        case .factory:
            if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                fatalError("Could not extract as factory unregistered service: \(T.self)")
            }

        case .both:
            if let singleton = state.singletons[ObjectIdentifier(T.self)] as? T {
                return singleton
            } else if let factory = state.factories[ObjectIdentifier(T.self)] as? () -> T {
                return factory()
            } else {
                fatalError("Could not extract as singleton or factory unregistered service: \(T.self)")
            }
        }
    }

    private func register<T>(factory: @escaping () -> T) {
        updateState {
            $0.factories[ObjectIdentifier(T.self)] = factory
        }
    }

    private func register<T>(singleton: T) {
        updateState {
            $0.singletons[ObjectIdentifier(T.self)] = singleton
        }
    }
}

public enum InjectorError: Error {
    case typeNotFound(message: String? = nil)
}

public enum InjectingType {

    // Use one already created object
    case singleton

    // Create a new object
    case factory

    // Firstly check singletons, then factories
    case both
}

public struct InjectorState: StateProtocol {

    public var singletons: [ObjectIdentifier: Any]
    public var factories: [ObjectIdentifier: Any]

    public init(singletons: [ObjectIdentifier : Any] = [:], factories: [ObjectIdentifier : Any] = [:]) {
        self.singletons = singletons
        self.factories = factories
    }
}

//
//  Injected.swift
//  Dufap
//
//  Created by Andrew Kuts
//

@propertyWrapper
public struct Injected<T> {

    private let injectType: InjectingType
    private var cached: T?

    public init(_ injectType: InjectingType = .both) {
        self.injectType = injectType
    }

    public var wrappedValue: T {
        mutating get {

            if let cached {
                return cached
            }

            guard let injector = InjectorRegistry.resolve() else {
                fatalError("Injector not registered in InjectorRegistry")
            }

            if T.self is AnyOptional.Type {

                let value: T? = injector.extractOptional(from: injectType)

                if let value {
                    cached = value
                    return value
                } else {
                    fatalError("Failed to resolve optional dependency of type \(T.self) using \(injectType)")
                }

            } else {

                let value: T = injector.extract(from: injectType)
                cached = value

                return value
            }
        }
    }
}

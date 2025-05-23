//
//  InjectorState.swift
//  Dufap
//
//  Created by Andrew Kuts
//


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
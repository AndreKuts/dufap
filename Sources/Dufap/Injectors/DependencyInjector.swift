//
//  DependencyInjector.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation

/**
 `DependencyInjector` is responsible for managing dependency injection within the application.
 It implements the `Injector` protocol and provides thread-safe mechanisms to manage and inject dependencies using `DispatchQueue`.
 */
public class DependencyInjector: Injector {

    /// Queue for safely updating the state
    public let updateStateQueue = DispatchQueue(label: "com.dufap.dependencies.injector")

    /// Current state of the `DependencyInjector`, holding singletons and factories
    public var state: InjectorState

    /// Initializes a new `DependencyInjector` with an empty state
    public init() {
        self.state = InjectorState()
    }
}

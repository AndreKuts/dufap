//
//  ProtectedStateHolder.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation

/**
 `ProtectedStateHolder` is a protocol that defines a contract for objects that manage a protected state.
 It provides a mechanism to ensure safe, synchronized access and updates to the state using a `DispatchQueue`.

 - Requirements:
    - A `State` conforming to `StateProtocol`.
    - An `updateStateQueue` for managing synchronous state updates.
 */
public protocol ProtectedStateHolder: AnyObject {

    /// The type of state managed by the object, conforming to `StateProtocol`.
    associatedtype S: StateProtocol

    /// The state instance being managed, conforming to the `StateProtocol`.
    var state: S { get set }

    /// A queue used to ensure that state updates are synchronized and thread-safe.
    var updateStateQueue: DispatchQueue { get }
}

public extension ProtectedStateHolder {

    /**
     Updates the state synchronously, ensuring thread safety by executing the update on `updateStateQueue`.

     - Parameters:
        - completion: A closure that is passed the `inout` state for modification.

     - Important:
        - This function guarantees that state modifications are thread-safe and synchronous.
     */
    func updateState(completion: @escaping (inout S) -> Void) {
        updateStateQueue.sync {
            completion(&state)
        }
    }
}

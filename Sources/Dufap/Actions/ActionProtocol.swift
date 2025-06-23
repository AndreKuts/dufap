//
//  ActionProtocol.swift
//  Dufap
//
//  Created by Andrew Kuts
//


/**
 `ActionProtocol` is a marker protocol used to define actions in the MVVM architecture.

 Conforming types represent user inputs or events that can trigger state changes.
 It separates synchronous and asynchronous actions via associated types and provides
 cancellation support via `cancelID`.
 */
public protocol ActionProtocol {

    /// The type representing synchronous actions.
    associatedtype SA: SyncActionProtocol

    /// The type representing asynchronous actions.
    associatedtype AA: AsyncActionProtocol

    /// Describes whether the action is `sync` or `async`.
    var triggerMode: TriggerMode { get }

    /// A unique identifier used for cancellation of async tasks.
    var cancelID: String { get }

}


/**
 Protocol that defines how a synchronous action can be initialized from a base action.

 Used internally to convert ``ActionProtocol`` into a more specialized sync form.
 */
public protocol SyncActionProtocol {

    /**
     Attempts to initialize a synchronous action from a general action.
     
     - Parameter original: The original action conforming to ``ActionProtocol``.
     - Returns: A sync-specific action or `nil` if the conversion isn't valid.
     */
    init?(from original: any ActionProtocol)
}


/**
 Protocol that defines how an asynchronous action can be initialized from a base action.

 Used internally to convert ``ActionProtocol`` into a more specialized async form.
 */
public protocol AsyncActionProtocol {

    /**
     Attempts to initialize an asynchronous action from a general action.

     - Parameter original: The original action conforming to ``ActionProtocol``.
     - Returns: An async-specific action or `nil` if the conversion isn't valid.
     */
    init?(from original: any ActionProtocol)
}


/**
 Provides a default implementation of ``triggerMode`` for actions,
 assuming synchronous behaviour unless otherwise specified.
 */
public extension ActionProtocol {
    var triggerMode: TriggerMode { .sync }
}

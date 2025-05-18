//
//  TriggerMode.swift
//  Dufap
//
//  Created by Andrew Kuts
//


/// Represents how an action should be triggered — synchronously or asynchronously.
@frozen
public enum TriggerMode {

    /// Action is triggered synchronously on the main thread.
    case sync

    /// Action is triggered asynchronously, using `Task`.
    case async
}

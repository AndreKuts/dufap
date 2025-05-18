//
//  InjectingType.swift
//  Dufap
//
//  Created by Andrew Kuts
//


/// Defines the type of injection for a dependency
public enum InjectingType {

    /// Use an already created singleton object
    case singleton

    /// Create a new object each time it's requested
    case factory

    /// Check both singletons first, then factories if the object is not found in singletons
    case both
}

//
//  InjectorError.swift
//  Dufap
//
//  Created by Andrew Kuts
//


/// Error type thrown when a dependency is not found in the injector's state.
public enum InjectorError: Error {
    case typeNotFound(message: String? = nil)
}
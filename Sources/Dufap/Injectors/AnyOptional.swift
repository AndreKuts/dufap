//
//  AnyOptional.swift
//  Dufap
//
//  Created by Andrew Kuts
//

/// A protocol used to identify and inspect `Optional` types at runtime.
public protocol AnyOptional {
    /// Returns the type that is wrapped by the optional.
    static func wrappedType() -> Any.Type
}

/// Extend Swift's built-in Optional to conform to `AnyOptional`
extension Optional: AnyOptional {

    /// Provides the wrapped type of the optional.
    ///
    /// For example, if the type is `Int?`, this will return `Int.self`.
    public static func wrappedType() -> Any.Type {
        Wrapped.self
    }
}

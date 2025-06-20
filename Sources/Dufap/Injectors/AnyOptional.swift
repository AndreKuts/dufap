//
//  AnyOptional.swift
//  Dufap
//
//  Created by Andrew Kuts
//

public protocol AnyOptional {
    static func wrappedType() -> Any.Type
}


extension Optional: AnyOptional {

    public static func wrappedType() -> Any.Type {
        Wrapped.self
    }
}

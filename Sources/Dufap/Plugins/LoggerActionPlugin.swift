//
//  LoggerActionPlugin.swift
//  Dufap
//
//  Created by Andrew Kuts
//


/**
 `LoggerActionPlugin` is a default implementation of ``ActionPlugin`` that logs action activity to the console.

 It can be useful during development and debugging to trace action flow.
 */
public struct LoggerActionPlugin: ActionPlugin {

    public init() { }

    public func willTrigger(action: any ActionProtocol) {
        print("🔄 Will trigger action \(type(of: action)): \(action) ->")
    }

    public func didTrigger(action: any ActionProtocol) {
        print("✅ Did trigger action \(type(of: action)): \(action) <-")
    }
}

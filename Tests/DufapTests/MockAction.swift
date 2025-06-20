//
//  MockAction.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation
import Dufap

@Action
enum MockAction {

    case sync(Int)
    case async(String)

    var triggerMode: TriggerMode {
        switch self {
        case .sync:
            return .sync
        case .async:
            return .async
        }
    }
}

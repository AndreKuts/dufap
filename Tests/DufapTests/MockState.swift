//
//  MockState.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation
@testable import Dufap

struct MockState: StateProtocol, Identifiable {
    var id: UUID = UUID()
    var value: Int
    var text: String
}

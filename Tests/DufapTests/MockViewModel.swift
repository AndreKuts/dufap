//
//  MockViewModel.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import Foundation
import XCTest
@testable import Dufap

@ViewModel(action: MockAction.self)
class MockViewModel {

    var state: MockState

    var asyncExpectation: XCTestExpectation?

    init(state: MockState, expect: XCTestExpectation? = nil) {
        self.asyncExpectation = expect
        self.state = state
    }

    func trigger(action: MockAction.SA) {
        switch action {
        case .sync(let intValue):
            state.value = intValue
        }
    }

    func triggerAsync(action: MockAction.AA) async {
        switch action {
        case .async(let stringValue):
            try? await Task.sleep(for: .seconds(1))
            state.text = stringValue
        }
        asyncExpectation?.fulfill()
    }
}

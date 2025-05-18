//
//  AnyViewModelTests.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import XCTest
import Combine
@testable import Dufap

class AnyViewModelTests: XCTestCase {

    let state = MockState(value: 10, text: "Ten")

    func testViewModelStateAccess() {

        let viewModel = AnyViewModel(MockViewModel(state: state))

        XCTAssertEqual(viewModel.value, state.value, "Expected value to match state.value, but got \(viewModel.value) instead of \(state.value)")
        XCTAssertEqual(viewModel.text, state.text, "Expected text to match state.text, but got '\(viewModel.text)' instead of '\(state.text)'")
        XCTAssertEqual(viewModel.id, state.id, "Expected id to match state.id, but got \(viewModel.id) instead of \(state.id)")
    }

    func testAsyncAction() {

        let exp = self.expectation(description: "Async Action triggered")
        let viewModel = AnyViewModel(MockViewModel(state: state, expect: exp))

        viewModel.trigger(action: .async("New Async Value"))
        waitForExpectations(timeout: 1.5)

        XCTAssertEqual(viewModel.text, "New Async Value", "Expected text to update after async action, but got '\(viewModel.text)' instead")
    }

    func testSyncAction() {

        let viewModel = AnyViewModel(MockViewModel(state: state))

        viewModel.trigger(action: .sync(1))
        XCTAssertEqual(viewModel.value, 1)
    }
}

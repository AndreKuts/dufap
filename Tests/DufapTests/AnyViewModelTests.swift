//
//  Copyright 2025 Andrew Kuts
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import Combine
import Dufap

class AnyViewModelTests: XCTestCase {

    let state = MockState(value: 10, text: "Ten")

    @MainActor
    func test_ViewModelStateAccess() {

        let viewModel = AnyViewModel(MockViewModel(state: state))

        XCTAssertEqual(viewModel.value, state.value, "Expected value to match state.value, but got \(viewModel.value) instead of \(state.value)")
        XCTAssertEqual(viewModel.text, state.text, "Expected text to match state.text, but got '\(viewModel.text)' instead of '\(state.text)'")
        XCTAssertEqual(viewModel.id, state.id, "Expected id to match state.id, but got \(viewModel.id) instead of \(state.id)")
    }

    @MainActor
    func test_AsyncAction() {

        let exp = self.expectation(description: "Async Action triggered")
        let vm = MockViewModel(state: state, expect: exp)
        let viewModel = AnyViewModel(vm)
        let newValue = "New Async Value"

        viewModel.trigger(action: .async(newValue))

        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.text, newValue, "Expected text to update after async action, but got '\(viewModel.text)' instead")
    }

    @MainActor
    func test_SyncAction() {

        let viewModel = AnyViewModel(MockViewModel(state: state))

        viewModel.trigger(action: .sync(1))

        XCTAssertEqual(viewModel.value, 1)
    }
}

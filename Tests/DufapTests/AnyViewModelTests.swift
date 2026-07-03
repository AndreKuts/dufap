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

@MainActor
class AnyViewModelTests: XCTestCase {

    let state = MockState(value: 10, text: "Ten")

    func test_ViewModelStateAccess() {

        let viewModel = AnyViewModel(MockViewModel(state: state))

        XCTAssertEqual(viewModel.value, state.value, "Expected value to match state.value, but got \(viewModel.value) instead of \(state.value)")
        XCTAssertEqual(viewModel.text, state.text, "Expected text to match state.text, but got '\(viewModel.text)' instead of '\(state.text)'")
        XCTAssertEqual(viewModel.id, state.id, "Expected id to match state.id, but got \(viewModel.id) instead of \(state.id)")
    }

    func test_AsyncActionUpdatesState() {

        let exp = self.expectation(description: "Async Action triggered")
        let vm = MockViewModel(state: state, asyncExpect: exp)
        let viewModel = AnyViewModel(vm)
        let newValue = "New Async Value"

        viewModel.trigger(action: .async(newValue))

        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.text, newValue, "Expected text to update after async action, but got '\(viewModel.text)' instead")
    }

    func test_SyncActionOnMainUpdatesStateImmediately() {

        let exp = self.expectation(description: "Sync Action triggered")
        let viewModel = AnyViewModel(MockViewModel(state: state, syncExpect: exp))

        viewModel.trigger(action: .sync(1))

        XCTAssertEqual(viewModel.value, 1)
        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.value, 1)
    }

    // The former "…FromBackground…" tests exercised runtime cross-thread dispatch
    // safety. Under @MainActor isolation that safety is a compile-time guarantee —
    // `trigger` / `state` are main-actor-isolated, so calling them off the main
    // actor is a compiler error (Swift 6). They are replaced by these
    // direct-contract tests.

    func test_syncAction_mutatesStateSynchronouslyOnMain() {
        let vm = MockViewModel(state: state)
        let viewModel = AnyViewModel(vm)

        viewModel.trigger(action: .sync(42))

        // No async hop under @MainActor — the mutation is visible immediately.
        XCTAssertEqual(viewModel.value, 42)
        XCTAssertTrue(vm.lastSyncMutationWasMainThread)
    }

    func test_wrappedStateChange_syncsToErasedViewModel() {
        let vm = MockViewModel(state: state)
        let viewModel = AnyViewModel(vm)

        vm.state.value = 77

        XCTAssertEqual(viewModel.value, 77)
    }

    func test_AsyncActionWithSameCancelIDCancelsPreviousTask() {

        let exp = self.expectation(description: "Latest async action triggered")
        let vm = MockViewModel(state: state, asyncExpect: exp)
        let viewModel = AnyViewModel(vm)

        viewModel.trigger(action: .asyncDelayed("old", 500_000_000))
        viewModel.trigger(action: .asyncDelayed("new", 10_000_000))

        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.text, "new")
    }
}

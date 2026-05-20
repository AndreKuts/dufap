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

    func test_SyncActionFromBackgroundIsScheduledOnMainThread() {

        let exp = self.expectation(description: "Background Sync Action triggered")
        let vm = MockViewModel(state: state, syncExpect: exp)
        let viewModel = AnyViewModel(vm)

        DispatchQueue.global().async {
            viewModel.trigger(action: .sync(42))
        }

        waitForExpectations(timeout: 2)

        XCTAssertTrue(vm.lastSyncMutationWasMainThread)
        XCTAssertEqual(viewModel.value, 42)
    }

    func test_StatePublisherFromBackgroundPublishesAnyViewModelStateOnMainThread() {

        let exp = self.expectation(description: "AnyViewModel publishes synchronized state on main")
        let vm = MockViewModel(state: state)
        let viewModel = AnyViewModel(vm)
        let lock = NSLock()
        var didPublishOnMainThread = false
        var cancellable: AnyCancellable?

        cancellable = viewModel.objectWillChange.sink {
            lock.lock()
            didPublishOnMainThread = Thread.isMainThread
            lock.unlock()

            exp.fulfill()
        }

        DispatchQueue.global().async {
            vm.state.value = 77
        }

        waitForExpectations(timeout: 2)

        lock.lock()
        let publishWasMainThread = didPublishOnMainThread
        lock.unlock()

        XCTAssertTrue(publishWasMainThread)
        XCTAssertEqual(viewModel.value, 77)
        _ = cancellable
    }

    func test_SyncActionFromBackgroundDoesNotMutateInline() {

        let exp = self.expectation(description: "Background Sync Action triggered")
        let vm = MockViewModel(state: state, syncExpect: exp)
        let viewModel = AnyViewModel(vm)
        let triggerReturned = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var valueImmediatelyAfterTrigger: Int?

        DispatchQueue.global().async {
            viewModel.trigger(action: .sync(99))

            lock.lock()
            valueImmediatelyAfterTrigger = viewModel.value
            lock.unlock()

            triggerReturned.signal()
        }

        XCTAssertEqual(triggerReturned.wait(timeout: .now() + 2), .success)

        lock.lock()
        let observedValue = valueImmediatelyAfterTrigger
        lock.unlock()

        XCTAssertEqual(observedValue, 10)

        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.value, 99)
    }

    func test_ManyBackgroundSyncActionsAreSerializedOnMainThread() {

        let actionCount = 200
        let exp = self.expectation(description: "All background sync actions triggered")
        exp.expectedFulfillmentCount = actionCount

        let vm = MockViewModel(state: state, syncExpect: exp)
        let viewModel = AnyViewModel(vm)
        let queue = DispatchQueue(label: "dufap.sync.stress", attributes: .concurrent)

        for _ in 0..<actionCount {
            queue.async {
                viewModel.trigger(action: .increment)
            }
        }

        waitForExpectations(timeout: 5)

        XCTAssertTrue(vm.lastSyncMutationWasMainThread)
        XCTAssertEqual(vm.syncMutationCount, actionCount)
        XCTAssertEqual(viewModel.value, state.value + actionCount)
    }

    func test_AsyncActionCanBeTriggeredFromBackground() {

        let exp = self.expectation(description: "Background Async Action triggered")
        let vm = MockViewModel(state: state, asyncExpect: exp)
        let viewModel = AnyViewModel(vm)
        let newValue = "Background Async Value"

        DispatchQueue.global().async {
            viewModel.trigger(action: .async(newValue))
        }

        waitForExpectations(timeout: 2)

        XCTAssertEqual(viewModel.text, newValue)
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

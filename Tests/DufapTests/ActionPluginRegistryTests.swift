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
import Dufap

final class ActionPluginRegistryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActionPluginRegistry.removeAll()
    }

    override func tearDown() {
        ActionPluginRegistry.removeAll()
        super.tearDown()
    }

    func test_RegisterPluginIsVisibleToImmediateTrigger() {
        let exp = expectation(description: "Plugin received immediately triggered action")
        let plugin = RecordingActionPlugin(expectedActionDescription: "sync(777)", expectation: exp)
        let viewModel = AnyViewModel(MockViewModel(state: MockState(value: 0, text: "")))

        ActionPluginRegistry.register(plugin)
        viewModel.trigger(action: .sync(777))

        waitForExpectations(timeout: 2)

        XCTAssertTrue(plugin.didTriggerExpectedAction)
    }
}

private final class RecordingActionPlugin: ActionPlugin {

    private let expectedActionDescription: String
    private let expectation: XCTestExpectation
    private let lock = NSLock()
    private var didTrigger = false

    var didTriggerExpectedAction: Bool {
        lock.lock()
        defer { lock.unlock() }

        return didTrigger
    }

    init(expectedActionDescription: String, expectation: XCTestExpectation) {
        self.expectedActionDescription = expectedActionDescription
        self.expectation = expectation
    }

    func willTrigger(action: any ActionProtocol) { }

    func didTrigger(action: any ActionProtocol) {
        guard String(describing: action) == expectedActionDescription else { return }

        lock.lock()
        didTrigger = true
        lock.unlock()

        expectation.fulfill()
    }
}

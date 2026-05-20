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

final class ActionLifecycleTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ActionPluginRegistry.removeAll()
    }

    override func tearDown() {
        ActionPluginRegistry.removeAll()
        super.tearDown()
    }

    func test_ActionTracerRecordsSyncLifecycle() {
        let tracer = ActionTracer()
        let viewModel = AnyViewModel(MockViewModel(state: MockState(value: 0, text: "")))

        ActionPluginRegistry.register(tracer)

        viewModel.trigger(action: .sync(10))

        let traces = tracer.traces
        XCTAssertEqual(traces.map(\.phase), [.willTrigger, .didTrigger])
        XCTAssertEqual(traces.last?.actionDescription, "sync(10)")
        XCTAssertNotNil(traces.last?.duration)
    }

    func test_ActionTracerRecordsCancellationLifecycle() async {
        let tracer = ActionTracer()
        let viewModel = AnyViewModel(MockViewModel(state: MockState(value: 0, text: "")))

        ActionPluginRegistry.register(tracer)

        XCTAssertEqual(
            MockAction.asyncDelayed("first", 500_000_000).cancelID,
            MockAction.asyncDelayed("second", 10_000_000).cancelID
        )
        viewModel.trigger(action: .asyncDelayed("first", 500_000_000))
        viewModel.trigger(action: .asyncDelayed("second", 10_000_000))

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(
            tracer.traces.contains { $0.phase == .didCancel },
            "\(tracer.traces.map(\.phase))"
        )
        XCTAssertTrue(
            tracer.traces.contains { $0.phase == .didTrigger },
            "\(tracer.traces.map(\.phase))"
        )
    }

    func test_ViewModelTesterSendsActionsAndExposesState() async {
        let tester = ViewModelTester(MockViewModel(state: MockState(value: 0, text: "")))

        let state = await tester.send(.sync(42))

        XCTAssertEqual(state.value, 42)
        XCTAssertTrue(tester.stateMatches { $0.value == 42 })
    }
}

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

final class CancellationTests: XCTestCase {

    func test_CancellableBagSameIDCancelsPreviousTask() async {
        let bag = CancellableBag()
        let first = CancellationProbe()

        makeSleepingTask(probe: first).store(in: bag, as: "load")
        Task<Void, Never> { }.store(in: bag, as: "load")

        await assertCancelled(first)
        bag.cancelAll()
    }

    func test_CancellableBagCancelAllCancelsAndRemovesTasksSynchronously() async {
        let bag = CancellableBag()
        let probe = CancellationProbe()

        makeSleepingTask(probe: probe).store(in: bag, as: "load")
        bag.cancelAll()

        XCTAssertNil(bag.cancel(id: "load"))
        await assertCancelled(probe)
    }

    func test_CancellationStoreSameIDCancelsPreviousTask() async {
        let store = CancellationStore()
        let first = CancellationProbe()

        await store.add(makeSleepingTask(probe: first), id: "load")
        await store.add(Task<Void, Never> { }, id: "load")

        await assertCancelled(first)
        await store.cancelAll()
    }

    func test_CancellationStoreCancelAllCancelsTasks() async {
        let store = CancellationStore()
        let probe = CancellationProbe()

        await store.add(makeSleepingTask(probe: probe), id: "load")
        await store.cancelAll()

        await assertCancelled(probe)
    }

    private func makeSleepingTask(probe: CancellationProbe) -> Task<Void, Never> {
        Task {
            await withTaskCancellationHandler {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            } onCancel: {
                probe.cancel()
            }
        }
    }

    private func assertCancelled(
        _ probe: CancellationProbe,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0..<100 {
            if probe.isCancelled {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Expected task to be cancelled", file: file, line: line)
    }
}

private final class CancellationProbe: @unchecked Sendable {

    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }

        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}

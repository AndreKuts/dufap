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

import Foundation
import XCTest
import Dufap

@MainActor
@ViewModel(action: MockAction.self)
class MockViewModel {

    var state: MockState

    var syncExpectation: XCTestExpectation?
    var asyncExpectation: XCTestExpectation?
    var lastSyncMutationWasMainThread = false
    var syncMutationCount = 0

    init(state: MockState, syncExpect: XCTestExpectation? = nil, asyncExpect: XCTestExpectation? = nil) {
        self.syncExpectation = syncExpect
        self.asyncExpectation = asyncExpect
        self.state = state
    }

    func trigger(action: MockAction.SA) {
        switch action {
        case .sync(let intValue):
            lastSyncMutationWasMainThread = Thread.isMainThread
            state.value = intValue
            syncMutationCount += 1
            syncExpectation?.fulfill()
        case .increment:
            lastSyncMutationWasMainThread = Thread.isMainThread
            state.value += 1
            syncMutationCount += 1
            syncExpectation?.fulfill()
        }
    }

    @MainActor
    func triggerAsync(action: MockAction.AA) async {
        switch action {
        case .async(let stringValue):
            try? await Task.sleep(nanoseconds: 100_000_000)

            state.text = stringValue
            asyncExpectation?.fulfill()
        case .asyncDelayed(let stringValue, let delay):
            try? await Task.sleep(nanoseconds: delay)

            guard !Task.isCancelled else { return }

            state.text = stringValue
            asyncExpectation?.fulfill()
        }
    }
}

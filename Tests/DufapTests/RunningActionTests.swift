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
@testable import Dufap

@MainActor
final class RunningActionTests: XCTestCase {

    private func makeViewModel() -> AnyViewModel<MockState, MockAction> {
        AnyViewModel(MockViewModel(state: MockState(value: 0, text: "")))
    }

    func test_replace_firstForCancelID_returnsNil() {
        let vm = makeViewModel()
        let previous = vm.replaceRunningAction(.async("a"), token: UUID(), cancelID: "id")
        XCTAssertNil(previous)
    }

    func test_replace_secondForSameCancelID_returnsPreviousAction() {
        let vm = makeViewModel()
        _ = vm.replaceRunningAction(.async("first"), token: UUID(), cancelID: "id")
        let previous = vm.replaceRunningAction(.async("second"), token: UUID(), cancelID: "id")

        guard case .async(let value)? = previous else {
            return XCTFail("Expected the displaced .async(\"first\") action, got \(String(describing: previous))")
        }
        XCTAssertEqual(value, "first")
    }

    func test_replace_differentCancelIDs_areIndependent() {
        let vm = makeViewModel()
        _ = vm.replaceRunningAction(.async("a"), token: UUID(), cancelID: "id-a")
        let previous = vm.replaceRunningAction(.async("b"), token: UUID(), cancelID: "id-b")
        XCTAssertNil(previous, "A different cancelID must not displace an unrelated entry")
    }

    func test_remove_matchingToken_removesAndReportsTrue() {
        let vm = makeViewModel()
        let token = UUID()
        _ = vm.replaceRunningAction(.async("a"), token: token, cancelID: "id")

        XCTAssertTrue(vm.removeRunningAction(cancelID: "id", token: token))
        XCTAssertFalse(vm.removeRunningAction(cancelID: "id", token: token))
    }

    func test_remove_staleToken_doesNotClearSuccessor() {
        let vm = makeViewModel()
        let oldToken = UUID()
        let newToken = UUID()
        _ = vm.replaceRunningAction(.async("first"), token: oldToken, cancelID: "id")
        _ = vm.replaceRunningAction(.async("second"), token: newToken, cancelID: "id")

        XCTAssertFalse(vm.removeRunningAction(cancelID: "id", token: oldToken))
        XCTAssertTrue(vm.removeRunningAction(cancelID: "id", token: newToken))
    }

    func test_remove_unknownCancelID_returnsFalse() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.removeRunningAction(cancelID: "never-started", token: UUID()))
    }
}

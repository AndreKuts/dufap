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

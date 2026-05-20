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

final class PathableTests: XCTestCase {

    func test_CaseIdentityIgnoresAssociatedValuesAndAllowsNonHashablePayloads() {
        let first = CaseRoute.details(NonHashablePayload(value: "1"))
        let second = CaseRoute.details(NonHashablePayload(value: "2"))

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.id, second.id)
    }

    func test_ValueIdentityUsesAssociatedValues() {
        let first = ValueRoute.details(id: "1")
        let second = ValueRoute.details(id: "2")

        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(first.id, second.id)
    }
}

private final class NonHashablePayload {
    let value: String

    init(value: String) {
        self.value = value
    }
}

@Pathable(.case)
private enum CaseRoute {
    case home
    case details(NonHashablePayload)
}

@Pathable(.value)
private enum ValueRoute {
    case home
    case details(id: String)
}

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

final class PrivacyLoggingTests: XCTestCase {

    func test_PrivacyMaskMasksPasswordsEmailsAndHiddenValues() {
        XCTAssertEqual(PrivacyMask.password("abc"), "••••••")
        XCTAssertEqual(PrivacyMask.password("supersecret"), String(repeating: "•", count: 11))
        XCTAssertEqual(PrivacyMask.email("andrew@example.com"), "a****@example.com")
        XCTAssertEqual(PrivacyMask.email("invalid"), "•••")
        XCTAssertEqual(PrivacyMask.hidden("token"), "••••")
    }

    func test_LoggerUsesLoggableActionDescription() {
        let action = SensitiveAction(email: "andrew@example.com", password: "secret")
        let description = LoggerActionPlugin().actionDescription(for: action)

        XCTAssertEqual(description, "login(a****@example.com, ••••••)")
        XCTAssertFalse(description.contains("andrew@example.com"))
        XCTAssertFalse(description.contains("secret"))
    }

    func test_LoggerFallsBackToStringDescribing() {
        let action = FallbackAction(value: 7)
        let description = LoggerActionPlugin().actionDescription(for: action)

        XCTAssertEqual(description, "fallback(7)")
    }

    func test_LoggerCanDisableLifecycleSide() {
        let plugin = LoggerActionPlugin(
            logsWillTrigger: false,
            logsDidTrigger: false,
            asyncOutput: false
        )

        plugin.willTrigger(action: FallbackAction(value: 1))
        plugin.didTrigger(action: FallbackAction(value: 1))

        XCTAssertEqual(plugin.actionDescription(for: FallbackAction(value: 1)), "fallback(1)")
    }
}

private struct SensitiveAction: ActionProtocol, LoggableAction {

    typealias SA = Never
    typealias AA = Never

    let email: String
    let password: String
    let cancelID = "sensitive"

    var logDescription: String {
        "login(\(PrivacyMask.email(email)), \(PrivacyMask.password(password)))"
    }
}

private struct FallbackAction: ActionProtocol, CustomStringConvertible {

    typealias SA = Never
    typealias AA = Never

    let value: Int
    let cancelID = "fallback"

    var description: String {
        "fallback(\(value))"
    }
}

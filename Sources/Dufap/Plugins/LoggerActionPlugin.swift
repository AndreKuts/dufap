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

/**
 `LoggerActionPlugin` is a default implementation of ``ActionPlugin`` that logs action activity to the console.

 It can be useful during development and debugging to trace action flow.
 */
public protocol LoggableAction {
    var logDescription: String { get }
}

public enum PrivacyMask {

    public static func password(_ value: String) -> String {
        String(repeating: "•", count: max(6, value.count))
    }

    public static func email(_ value: String) -> String {
        guard let at = value.firstIndex(of: "@") else { return "•••" }

        let name = value[..<at]
        let masked = String(name.prefix(1)) + "****"
        return masked + String(value[at...])
    }

    public static func hidden(_ value: String) -> String {
        "••••"
    }
}

public struct LoggerActionPlugin: ActionPlugin {

    private static let outputQueue = DispatchQueue(label: "com.dufap.logger_action_plugin.output")

    private let logsWillTrigger: Bool
    private let logsDidTrigger: Bool
    private let asyncOutput: Bool

    public init(
        logsWillTrigger: Bool = true,
        logsDidTrigger: Bool = true,
        asyncOutput: Bool = true
    ) {
        self.logsWillTrigger = logsWillTrigger
        self.logsDidTrigger = logsDidTrigger
        self.asyncOutput = asyncOutput
    }

    public func willTrigger(action: any ActionProtocol) {
        guard logsWillTrigger else { return }

        log("🔄 Will trigger action \(type(of: action)): \(actionDescription(for: action)) ->")
    }

    public func didTrigger(action: any ActionProtocol) {
        guard logsDidTrigger else { return }

        log("✅ Did trigger action \(type(of: action)): \(actionDescription(for: action)) <-")
    }

    public func didCancel(action: any ActionProtocol) {
        log("⏹️ Did cancel action \(type(of: action)): \(actionDescription(for: action))")
    }

    public func didFail(action: any ActionProtocol, errorDescription: String?) {
        let error = errorDescription.map { " error=\($0)" } ?? ""
        log("❌ Did fail action \(type(of: action)): \(actionDescription(for: action))\(error)")
    }

    public func actionDescription(for action: any ActionProtocol) -> String {
        ActionLogDescription.describe(action)
    }

    private func log(_ message: String) {
        if asyncOutput {
            Self.outputQueue.async {
                print(message)
            }
        } else {
            print(message)
        }
    }
}

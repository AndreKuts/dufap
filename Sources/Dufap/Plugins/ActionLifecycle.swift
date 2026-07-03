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

public enum ActionLifecyclePhase: Equatable {
    case willTrigger
    case didTrigger
    case didCancel
    case didFail
}

public struct ActionLifecycleEvent {
    public let phase: ActionLifecyclePhase
    public let action: any ActionProtocol
    public let timestamp: Date
    public let actionDescription: String
    public let duration: TimeInterval?
    public let errorDescription: String?

    public init(
        phase: ActionLifecyclePhase,
        action: any ActionProtocol,
        timestamp: Date = Date(),
        actionDescription: String? = nil,
        duration: TimeInterval? = nil,
        errorDescription: String? = nil
    ) {
        self.phase = phase
        self.action = action
        self.timestamp = timestamp
        self.actionDescription = actionDescription ?? ActionLogDescription.describe(action)
        self.duration = duration
        self.errorDescription = errorDescription
    }
}

public enum ActionLogDescription {

    public static func describe(_ action: any ActionProtocol) -> String {
        if let action = action as? any LoggableAction {
            return action.logDescription
        }

        return String(describing: action)
    }
}

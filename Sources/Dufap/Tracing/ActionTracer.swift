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

public struct ActionTrace: Equatable {
    public let phase: ActionLifecyclePhase
    public let actionType: String
    public let actionDescription: String
    public let timestamp: Date
    public let duration: TimeInterval?
    public let errorDescription: String?

    public init(
        phase: ActionLifecyclePhase,
        actionType: String,
        actionDescription: String,
        timestamp: Date,
        duration: TimeInterval?,
        errorDescription: String?
    ) {
        self.phase = phase
        self.actionType = actionType
        self.actionDescription = actionDescription
        self.timestamp = timestamp
        self.duration = duration
        self.errorDescription = errorDescription
    }
}

public final class ActionTracer: ActionPlugin {

    private let lock = NSLock()
    private let limit: Int
    private var tracesStorage: [ActionTrace] = []
    private var startTimes: [String: Date] = [:]

    public init(limit: Int = 200) {
        self.limit = max(1, limit)
    }

    public var traces: [ActionTrace] {
        lock.lock()
        let traces = tracesStorage
        lock.unlock()
        return traces
    }

    public func removeAll() {
        lock.lock()
        tracesStorage.removeAll()
        startTimes.removeAll()
        lock.unlock()
    }

    public func willTrigger(action: any ActionProtocol) {
        append(phase: .willTrigger, action: action)
    }

    public func didTrigger(action: any ActionProtocol) {
        append(phase: .didTrigger, action: action)
    }

    public func didCancel(action: any ActionProtocol) {
        append(phase: .didCancel, action: action)
    }

    public func didFail(action: any ActionProtocol, errorDescription: String?) {
        append(phase: .didFail, action: action, errorDescription: errorDescription)
    }

    private func append(
        phase: ActionLifecyclePhase,
        action: any ActionProtocol,
        errorDescription: String? = nil
    ) {
        let now = Date()
        let key = traceKey(for: action)
        let duration: TimeInterval?

        lock.lock()

        if phase == .willTrigger {
            startTimes[key] = now
            duration = nil
        } else {
            duration = startTimes[key].map { now.timeIntervalSince($0) }
            startTimes[key] = nil
        }

        tracesStorage.append(ActionTrace(
            phase: phase,
            actionType: String(describing: type(of: action)),
            actionDescription: ActionLogDescription.describe(action),
            timestamp: now,
            duration: duration,
            errorDescription: errorDescription
        ))

        if tracesStorage.count > limit {
            tracesStorage.removeFirst(tracesStorage.count - limit)
        }

        lock.unlock()
    }

    private func traceKey(for action: any ActionProtocol) -> String {
        "\(String(describing: type(of: action)))::\(action.cancelID)"
    }
}


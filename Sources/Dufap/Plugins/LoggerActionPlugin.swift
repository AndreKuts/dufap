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

/**
 `LoggerActionPlugin` is a default implementation of ``ActionPlugin`` that logs action activity to the console.

 It can be useful during development and debugging to trace action flow.
 */
public struct LoggerActionPlugin: ActionPlugin {

    public init() { }

    public func willTrigger(action: any ActionProtocol) {
        print("🔄 Will trigger action \(type(of: action)): \(action) ->")
    }

    public func didTrigger(action: any ActionProtocol) {
        print("✅ Did trigger action \(type(of: action)): \(action) <-")
    }
}

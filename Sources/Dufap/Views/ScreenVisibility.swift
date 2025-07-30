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

/// A visibility state for showing or hiding a view, optionally with a view model.
///
/// Useful for controlling animated transitions or conditional presentation in SwiftUI.
///
/// - T: The associated view model or state.
@frozen
public enum ScreenVisibility<T>: Hashable, Equatable, Identifiable {

    public static func == (lhs: ScreenVisibility<T>, rhs: ScreenVisibility<T>) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id: Int {
        switch self {
        case .show:
            return 0
        case .hide:
            return 1
        }
    }

    /// Indicates that the screen should be shown, with the type.
    case show(T)

    /// Hide the view
    case hide
}

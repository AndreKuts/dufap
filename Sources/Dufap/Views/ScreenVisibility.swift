//
//  ScreenVisibility.swift
//  Dufap
//
//  Created by Andrew Kuts
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

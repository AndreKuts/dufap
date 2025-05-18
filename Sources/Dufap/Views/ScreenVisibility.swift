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
@Pathable
@frozen public enum ScreenVisibility<T> {

    /// Indicates that the screen should be shown, with the type.
    case show(T)

    /// Hide the view
    case hide
}

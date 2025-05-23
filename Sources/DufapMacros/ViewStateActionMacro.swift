//
//  ViewStateActionMacro.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - ViewStateActionMacro
/**
 `ViewStateActionMacro` is a macro that generates extensions and members for SwiftUI views conforming to the `ViewProtocol`.
 This macro establishes the necessary properties and extensions for views that utilize a specified state and action.

 - Usage:
 Apply the `@ViewWith` macro to a SwiftUI view struct to automatically generate the required properties and extensions.

 - How it Works:
 The macro performs the following tasks:
 - Generates an extension for the view type to conform to `ViewProtocol`.

 - Requirements:
 - The view must be declared with `@ViewWith`, including state and action types.
 - The state type must conform to `StateProtocol`.
 - The action type must conform to `ActionProtocol`.

 - Error Handling:
 If the macro cannot parse the state or action type arguments, it throws a `MacroError.dufapGeneralError`.

 - Example:

 ```swift
 @ViewWith(state: MyState.self, action: MyAction.self)
 struct MyView: View {
    var body: some View {
    // Your view implementation here
    }
 }
 ```

 - Limitations:
 - The macro assumes that the provided state and action types are valid and conform to the required protocols.
 - Does not handle nested structures or complex view hierarchies automatically.

 - Supported Types:
 Any SwiftUI view that needs to bind to a specific state and action type, ensuring conformance to `ViewProtocol`.
 */

public enum ViewStateActionMacro: ExtensionMacro, MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        let syntax: DeclSyntax =
            """
            extension \(type.trimmed): ViewProtocol { }
            """

        return [syntax.cast(ExtensionDeclSyntax.self)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

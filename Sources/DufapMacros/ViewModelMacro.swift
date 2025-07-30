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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// MARK: - ViewModelMacro
/**
 `ViewModelMacro` is a macro that generates a ViewModel conforming to the `ViewModelProtocol`.
 It automatically manages state updates and facilitates integration with SwiftUI views.

 - Usage:
 Apply the `@ViewModel` macro to a class or struct to create a ViewModel that adheres to the `ViewModelProtocol`.

 - How it Works:
 The macro performs the following tasks:
 - Generates an extension for the ViewModel type to conform to `ViewModelProtocol`.
 - Creates a member property named `updateStateQueue`, which is a DispatchQueue used for synchronizing state updates.

 - Example:

 ```swift
 @ViewModel
 class MyViewModel {
 // Define state and actions here
 }
 ```

 - Requirements:
 - The ViewModel must have a state conforming to `StateProtocol`.
 - The ViewModel must have actions conforming to `ActionProtocol`.
 - Limitations:
 - The macro is intended for standard use cases; complex state management may still require manual implementations.
 - Custom properties or methods in the ViewModel must be defined separately.
 - Supported Types:
 Any class or struct designed to function as a ViewModel in an MVVM pattern, ensuring adherence to the defined protocols.
 */
public enum ViewModelMacro { }

extension ViewModelMacro: ExtensionMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        let viewModel: DeclSyntax = "extension \(type.trimmed): ViewModelProtocol { }"

        return [
            viewModel.cast(ExtensionDeclSyntax.self),
        ]
    }
}

extension ViewModelMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let args = declaration.attributes.compactMap { $0.as(AttributeSyntax.self) }.first?.arguments
        let actionType = args?.as(LabeledExprListSyntax.self)?.first?.expression.as(MemberAccessExprSyntax.self)?.base?.as(DeclReferenceExprSyntax.self)?.baseName.text ?? ""

        return [
            """
            typealias A = \(raw: actionType)

            var bag: CancellableBag = CancellableBag()

            var updateStateQueue = DispatchQueue(label: "com.dufap.state.update.\(raw: declaration.as(ClassDeclSyntax.self)?.name.text.lowercased() ?? "unknown_object")")

            var statePublisher: Published<S>.Publisher { $state }
            """
        ]
    }
}

extension ViewModelMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {

        let memberId = member
            .as(VariableDeclSyntax.self)?
            .bindings
            .compactMap {
                $0.pattern
                    .as(IdentifierPatternSyntax.self)?
                    .identifier
                    .text
            }.first ?? ""

        return memberId == "state" ? ["@Published"] : []
    }
}

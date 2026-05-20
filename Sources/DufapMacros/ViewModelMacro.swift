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
import SwiftDiagnostics

// MARK: - ViewModelMacro
/**
 `ViewModelMacro` is a macro that generates a ViewModel conforming to the `ViewModelProtocol`.
 It automatically manages state updates and facilitates integration with SwiftUI views.

 - Usage:
 Apply the `@ViewModel` macro to a class or struct to create a ViewModel that adheres to the `ViewModelProtocol`.

 - How it Works:
 The macro performs the following tasks:
 - Generates an extension for the ViewModel type to conform to `ViewModelProtocol`.

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

private struct ViewModelMacroArguments {
    let actionType: String
}

extension ViewModelMacro: ExtensionMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        guard isSupportedViewModelDeclaration(declaration),
              parseArguments(from: node, diagnoseIn: nil) != nil else {
            return []
        }

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

        guard isSupportedViewModelDeclaration(declaration) else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`@ViewModel` can only be applied to a class or struct. Use `@ViewModel(action: MyAction.self)` on a ViewModel type.")
            ))
            return []
        }

        guard let arguments = parseArguments(from: node, diagnoseIn: context) else {
            return []
        }

        return [
            """
            typealias A = \(raw: arguments.actionType)

            var bag: CancellableBag = CancellableBag()

            var statePublisher: Published<S>.Publisher { $state }
            """
        ]
    }
}

private func isSupportedViewModelDeclaration(_ declaration: some DeclGroupSyntax) -> Bool {
    declaration.is(ClassDeclSyntax.self) || declaration.is(StructDeclSyntax.self)
}

private func parseArguments(
    from node: AttributeSyntax,
    diagnoseIn context: (any MacroExpansionContext)?
) -> ViewModelMacroArguments? {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
          let argument = arguments.first,
          argument.label?.text == "action" else {
        context?.diagnose(Diagnostic(
            node: Syntax(node),
            message: SimpleDiagnostic(message: "`@ViewModel` requires an action type. Use `@ViewModel(action: MyAction.self)`.")
        ))
        return nil
    }

    guard let memberAccess = argument.expression.as(MemberAccessExprSyntax.self),
          memberAccess.declName.baseName.text == "self",
          let actionType = memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text else {
        context?.diagnose(Diagnostic(
            node: Syntax(argument),
            message: SimpleDiagnostic(message: "`@ViewModel` action argument must use `.self`. Use `@ViewModel(action: MyAction.self)`.")
        ))
        return nil
    }

    return ViewModelMacroArguments(actionType: actionType)
}

extension ViewModelMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard isSupportedViewModelDeclaration(declaration),
              parseArguments(from: node, diagnoseIn: nil) != nil else {
            return []
        }

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

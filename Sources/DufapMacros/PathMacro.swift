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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct PathMacro: ExtensionMacro {

    private enum IdentityMode {
        case `case`
        case value
        case invalid
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`@Pathable` can only be applied to enums.")
            ))
            return []
        }

        let modifiers = enumDecl.modifiers
        let accessModifier = modifiers.first(where: { ["public", "internal", "fileprivate", "private"].contains($0.name.text) })?.name.text
        let access = accessModifier.map { $0 == "private" ? "fileprivate " : "\($0) " } ?? ""
        let enumName = enumDecl.name.text

        switch identityMode(from: node) {
        case .case:
            return [caseIdentityExtension(enumDecl: enumDecl, enumName: enumName, access: access)]
        case .value:
            return [valueIdentityExtension(enumName: enumName, access: access)]
        case .invalid:
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`@Pathable` supports `.case` and `.value` identity modes.")
            ))
            return []
        }
    }

    private static func identityMode(from node: AttributeSyntax) -> IdentityMode {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArgument = arguments.first else {
            return .case
        }

        guard let memberName = firstArgument.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text else {
            return .invalid
        }

        switch memberName {
        case "case":
            return .case
        case "value":
            return .value
        default:
            return .invalid
        }
    }

    private static func caseIdentityExtension(
        enumDecl: EnumDeclSyntax,
        enumName: String,
        access: String
    ) -> ExtensionDeclSyntax {

        let cases = enumDecl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements }
            .flatMap { $0 }
            .enumerated().map { "case .\($1.name.text): return \($0)" }
            .joined(separator: "\n")

        let extensionCode: DeclSyntax = """
            extension \(raw: enumName): Hashable, Equatable, Identifiable {

                \(raw: access)static func == (lhs: \(raw: enumName), rhs: \(raw: enumName)) -> Bool {
                    lhs.index == rhs.index
                }

                \(raw: access)func hash(into hasher: inout Hasher) {
                    hasher.combine(index)
                }

                \(raw: access)var index: Int {
                    switch self {
            \(raw: cases)
                    }
                }

                \(raw: access)var id: Int { index }

            }
            """

        return extensionCode.cast(ExtensionDeclSyntax.self)
    }

    private static func valueIdentityExtension(
        enumName: String,
        access: String
    ) -> ExtensionDeclSyntax {

        let extensionCode: DeclSyntax = """
            extension \(raw: enumName): Hashable, Equatable, Identifiable {

                \(raw: access)var id: Self { self }

            }
            """

        return extensionCode.cast(ExtensionDeclSyntax.self)
    }
}

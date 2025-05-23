//
//  PathMacro.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public struct PathMacro: ExtensionMacro {

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
        let access = accessModifier.map { "\($0) " } ?? ""

        let cases = enumDecl.memberBlock.members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements }
            .flatMap { $0 }
            .enumerated().map { "case .\($1.name.text): return \($0)" }
            .joined(separator: "\n")

        let enumName = enumDecl.name.text
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

        return [extensionCode.cast(ExtensionDeclSyntax.self)]
    }
}

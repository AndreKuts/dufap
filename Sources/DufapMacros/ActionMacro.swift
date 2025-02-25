//
//  ActionMacro.swift
//  Dufap
//
//  Created by Andrew Kuts on 2025-04-10.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

public enum ActionMacro: MemberMacro, ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`@ActionMacro` can only be applied to enums.")
            ))
            return []
        }

        let syncDecl =
            """
            typealias SA = SyncAction
            """

        let neverAsync =
            """
            typealias AA = Never
            """

        let members = enumDecl.memberBlock.members
        guard let triggerModeVarDecl = members.first(where: {
            $0.decl.is(VariableDeclSyntax.self) && $0.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "triggerMode"
        }) else {

            let caseNames = members.compactMap { member -> String? in
                guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self),
                      let firstCase = enumCase.elements.first else {
                    return nil
                }
                return firstCase.name.text
            }

            return [
                DeclSyntax(stringLiteral: makeEnum(name: "SyncAction", cases: caseNames)),
                DeclSyntax(stringLiteral: makeEnum(name: "AsyncAction", cases: [])),
                DeclSyntax(stringLiteral: syncDecl),
                DeclSyntax(stringLiteral: neverAsync),
            ]
        }

        guard let switchCases = triggerModeVarDecl.decl
            .as(VariableDeclSyntax.self)?
            .bindings
            .first(where: { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "triggerMode"})?
            .accessorBlock?
            .accessors
            .as(CodeBlockItemListSyntax.self)?
            .first?
            .item
            .as(ExpressionStmtSyntax.self)?
            .expression
            .as(SwitchExprSyntax.self)?
            .cases
        else {
            let caseNames = members.compactMap { member -> String? in
                guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self),
                      let firstCase = enumCase.elements.first else {
                    return nil
                }
                return firstCase.name.text
            }

            return [
                DeclSyntax(stringLiteral: makeEnum(name: "SyncAction", cases: caseNames)),
                DeclSyntax(stringLiteral: makeEnum(name: "AsyncAction", cases: [])),
                DeclSyntax(stringLiteral: syncDecl),
                DeclSyntax(stringLiteral: neverAsync),
            ]
        }

        var syncCases: [String] = []
        var asyncCases: [String] = []

        for switchCase in switchCases {
            guard let caseSyntax = switchCase.as(SwitchCaseSyntax.self),
                  let name = caseSyntax.statements.first?.item.as(ReturnStmtSyntax.self)?.expression?.as(MemberAccessExprSyntax.self)?.declName.baseName.text,
                  let caseItems = caseSyntax.label.as(SwitchCaseLabelSyntax.self)?.caseItems
            else {
                continue
            }

            let caseItemNames = caseItems.compactMap { $0.pattern.as(ExpressionPatternSyntax.self)?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text }

            if name == "sync" {
                caseItemNames.forEach { syncCases.append($0) }
            } else if name == "async" {
                caseItemNames.forEach { asyncCases.append($0) }
            }
        }

        func makeEnum(name: String, cases: [String]) -> String {
            let casesDecl = cases.map { "case \($0)" }.joined(separator: "\n")
            let nameDecl = "\(name)Protocol"

            let source = """
                enum \(name): \(nameDecl) {
                \(casesDecl)
                }
                """
            return source
        }

        let caseNames = members.compactMap { member -> String? in
            guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self),
                  let firstCase = enumCase.elements.first else {
                return nil
            }
            return firstCase.name.text
        }

        let cases = caseNames
            .map { "    case .\($0): return \"cancel_\($0)\"" }
            .joined(separator: "\n")

        let cancelIDDecl = """
        var cancelID: String {
            switch self {
        \(cases)
            }
        }
        """

        let asyncDecl =
        """
        typealias AA = AsyncAction
        """

        return [
            DeclSyntax(stringLiteral: cancelIDDecl),
            DeclSyntax(stringLiteral: makeEnum(name: "SyncAction", cases: syncCases)),
            DeclSyntax(stringLiteral: makeEnum(name: "AsyncAction", cases: asyncCases)),
            DeclSyntax(stringLiteral: syncDecl),
            DeclSyntax(stringLiteral: asyncDecl),
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        let syntax: DeclSyntax =
            """
            extension \(type.trimmed): ActionProtocol { }
            """

        return [syntax.cast(ExtensionDeclSyntax.self)]
    }
}

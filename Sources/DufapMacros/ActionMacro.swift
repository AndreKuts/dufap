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

        let originalEnumName = enumDecl.name.text

        let syncDecl = "typealias SA = SyncAction"
        let neverSync = "typealias SA = Never"

        let neverAsync = "typealias AA = Never"
        let asyncDecl = "typealias AA = AsyncAction"

        let members = enumDecl.memberBlock.members
        let allCasesWithTypes = makeCaseWithTypes(memberList: members)
        let totalCount = allCasesWithTypes.count
        let cases = allCasesWithTypes
            .map { "    case .\($0.name): return \"cancel_\($0.name)\"" }
            .joined(separator: "\n")

        let cancelIDDecl = """
        var cancelID: String {
            switch self {
        \(cases)
            }
        }
        """

        guard let triggerModeVarDecl = members.first(
            where: {
                $0.decl.is(VariableDeclSyntax.self)
                && $0.decl.as(VariableDeclSyntax.self)?.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "triggerMode"
            }
        ) else {

            let result = [
                cancelIDDecl,
                makeEnum(name: "SyncAction", cases: allCasesWithTypes, totalCount: totalCount, originalEnumName: originalEnumName),
                makeEnum(name: "AsyncAction", cases: [], totalCount: totalCount, originalEnumName: originalEnumName),
                allCasesWithTypes.isEmpty ? neverSync : syncDecl,
                neverAsync,
            ]
            .compactMap { $0 }
            .map { DeclSyntax(stringLiteral: $0) }

            return result
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
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`triggerMode` must be a computed property with a switch on self")
            ))
            return []
        }

        var syncCases: [CaseInfo] = []
        var asyncCases: [CaseInfo] = []
        var handeledNames: [String] = []

        for switchCase in switchCases {
            if let caseSyntax = switchCase.as(SwitchCaseSyntax.self),
               let name = caseSyntax.statements.first?.item.as(ReturnStmtSyntax.self)?.expression?.as(MemberAccessExprSyntax.self)?.declName.baseName.text,
               let caseItems = caseSyntax.label.as(SwitchCaseLabelSyntax.self)?.caseItems {

                let caseItemNames = caseItems.compactMap { $0.pattern.as(ExpressionPatternSyntax.self)?.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text }

                if name == "sync" {
                    for caseItemName in caseItemNames {
                        if let caseWithType = allCasesWithTypes.first(where: { $0.name == caseItemName }) {
                            syncCases.append(caseWithType)
                            handeledNames.append(caseItemName)
                        }
                    }
                } else

                if name == "async" {
                    for caseItemName in caseItemNames {
                        if let caseWithType = allCasesWithTypes.first(where: { $0.name == caseItemName }) {
                            asyncCases.append(caseWithType)
                            handeledNames.append(caseItemName)
                        }
                    }
                }

                else {
                    context.diagnose(Diagnostic(
                        node: Syntax(switchCase),
                        message: SimpleDiagnostic(message: "Only `sync` and `async` trigger modes are supported")
                    ))
                    return []
                }

            } else

            if let defaulLabel = switchCase.as(SwitchCaseSyntax.self)?.label.as(SwitchDefaultLabelSyntax.self),
               defaulLabel.defaultKeyword.text == "default",
               let defaulReturn = switchCase.as(SwitchCaseSyntax.self)?.statements.first?.item.as(ReturnStmtSyntax.self)?.expression?.as(MemberAccessExprSyntax.self)?.declName.baseName.text {

                let unhendeledCases = allCasesWithTypes.filter { !handeledNames.contains($0.name) }

                if defaulReturn == "sync" {
                    syncCases.append(contentsOf: unhendeledCases)
                } else if defaulReturn == "async" {
                    asyncCases.append(contentsOf: unhendeledCases)
                } else {
                    context.diagnose(Diagnostic(
                        node: Syntax(switchCase),
                        message: SimpleDiagnostic(message: "Only `sync` and `async` trigger modes are supported")
                    ))
                    return []
                }
            }
        }

        let result = [
            cancelIDDecl,
            makeEnum(name: "SyncAction", cases: syncCases, totalCount: totalCount, originalEnumName: originalEnumName),
            makeEnum(name: "AsyncAction", cases: asyncCases, totalCount: totalCount, originalEnumName: originalEnumName),
            syncCases.isEmpty ? neverSync : syncDecl,
            asyncCases.isEmpty ? neverAsync : asyncDecl,
        ]
        .compactMap { $0 }
        .map { DeclSyntax(stringLiteral: $0) }

        return result
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let syntax: DeclSyntax = "extension \(type.trimmed): ActionProtocol { }"
        return [syntax.cast(ExtensionDeclSyntax.self)]
    }

    private static func makeEnum(name: String, cases: [CaseInfo], totalCount: Int, originalEnumName: String) -> String? {
        guard !cases.isEmpty else {
            return nil
        }

        let sortedCases = cases.sorted { $0.name < $1.name }
        let casesDecl = sortedCases
            .map { $0.asString() }
            .joined(separator: "\n")

        let nameDecl = "\(name)Protocol"

        let initCases = sortedCases.map { caseInfo -> String in
            guard let params = caseInfo.parameters, !params.isEmpty else {
                return "    case .\(caseInfo.name): self = .\(caseInfo.name)"
            }

            let pattern = params.enumerated().map { idx, param in
                let varName = param.secondName ?? param.firstName ?? "param\(idx)"
                return "let \(varName)"
            }
            .joined(separator: ", ")

            let initArgs = params.enumerated().map { idx, param in
                let label = param.firstName ?? "_"
                let varName = param.secondName ?? param.firstName ?? "param\(idx)"
                return "\(label): \(varName)"
            }
            .joined(separator: ", ")

            return "    case .\(caseInfo.name)(\(pattern)): self = .\(caseInfo.name)(\(initArgs))"
        }
        .joined(separator: "\n")

        let defaultNil = cases.count == totalCount ? "" : "default: return nil"
        let initDecl = """

        init?(from original: any ActionProtocol) {
            guard let original = original as? \(originalEnumName) else { return nil }
            switch original {
            \(initCases)
            \(defaultNil)
            }
        }
        """

        return """
        enum \(name): \(nameDecl) {
        \(initDecl)

        \(casesDecl)
        }
        """
    }

    private static func makeCaseWithTypes(memberList: MemberBlockItemListSyntax) -> [CaseInfo] {
        var cases: [CaseInfo] = []

        for block in memberList {
            guard let enumCase = block.decl.as(EnumCaseDeclSyntax.self) else { continue }

            for element in enumCase.elements {
                let name = element.name.text
                let parameters: [CaseParameterInfo]? = element.parameterClause?.parameters.map { param in
                    let firstName = param.firstName?.text
                    let secondName = param.secondName?.text
                    let type = param.type.trimmedDescription
                    let defaultValue = param.defaultValue?.value.trimmedDescription ?? nil

                    return CaseParameterInfo(
                        firstName: firstName,
                        secondName: secondName,
                        type: type,
                        defaultValue: defaultValue
                    )
                }

                cases.append(CaseInfo(name: name, parameters: parameters))
            }
        }

        return cases
    }
}

extension SyntaxProtocol {
    var trimmedDescription: String {
        self.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct CaseInfo {

    let name: String
    let parameters: [CaseParameterInfo]?

    func asString() -> String {
        guard let parameters, !parameters.isEmpty else {
            return "case \(name)"
        }

        let paramList = parameters.map { param -> String in
            let first = param.firstName ?? "_"
            let second = param.secondName.map { " \($0)" } ?? ""
            let type = param.type
            let defaultVal = param.defaultValue.map { " = \($0)" } ?? ""
            return "\(first)\(second): \(type)\(defaultVal)"
        }.joined(separator: ", ")

        return "case \(name)(\(paramList))"
    }
}

struct CaseParameterInfo {
    let firstName: String?
    let secondName: String?
    let type: String
    let defaultValue: String?
}

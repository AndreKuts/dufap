import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ViewStateActionMacro { }
public enum ViewModelMacro { }

enum MacroError: Error {
    case dufapGeneralError(String)
}

extension ViewModelMacro: ExtensionMacro {

    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, 
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

        let viewModel: DeclSyntax =
            """
            extension \(type.trimmed): ViewModelProtocol { }
            """

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
        return [
            """
            var updateStateQueue = DispatchQueue(label: "com.dufap.state.update.\(raw: declaration.as(ClassDeclSyntax.self)?.name.text.lowercased() ?? "unknown_object")")
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

extension ViewStateActionMacro: ExtensionMacro {
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
}

extension ViewStateActionMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard
            let structDecl: StructDeclSyntax = declaration.as(StructDeclSyntax.self),
            let argumentsList = structDecl.attributes.first?
                .as(AttributeSyntax.self)?.arguments?
                .as(LabeledExprListSyntax.self),
            let stateArgument = argumentsList.first(where: { $0.label?.text == "state" }),
            let actionArgument = argumentsList.first(where: { $0.label?.text == "action" }),
            let stateType = stateArgument.expression
                .as(MemberAccessExprSyntax.self)?.base?
                .as(DeclReferenceExprSyntax.self)?
                .baseName.text 
				?? stateArgument.expression
				.as(DeclReferenceExprSyntax.self)?.baseName.text,
            let actionType = actionArgument.expression
                .as(MemberAccessExprSyntax.self)?.base?
                .as(DeclReferenceExprSyntax.self)?
				.baseName.text 
				?? actionArgument.expression
				.as(DeclReferenceExprSyntax.self)?.baseName.text

        else {
            throw MacroError.dufapGeneralError("Parsing State and/or Action type arguments")
        }

        return [
            DeclSyntax(
                """
                @ObservedObject 
                var viewModel: AnyViewModel<\(raw: stateType), \(raw: actionType)>
                """
            )
        ]
    }
}

@main
struct DufapPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ViewStateActionMacro.self,
        ViewModelMacro.self,
    ]
}

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum ViewStateActionMacro {
	enum Error: Swift.Error {
		case generalError(String)
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
            let argumentsList = structDecl.attributes
                .as(AttributeListSyntax.self)?.first?
                .as(AttributeSyntax.self)?.arguments?
                .as(LabeledExprListSyntax.self)?
                .compactMap({ $0.as(LabeledExprSyntax.self) }),
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
			throw Error.generalError("Parsing State and/or Action type arguments")
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

extension ViewStateActionMacro: MemberAttributeMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AttributeSyntax] {
        []
    }
}

@main
struct DufapPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ViewStateActionMacro.self
    ]
}

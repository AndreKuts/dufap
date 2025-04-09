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
public enum ViewStateActionMacro { }

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
        return []
    }
}

public enum CancelableActionMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        let syntax: DeclSyntax =
            """
            extension \(type.trimmed): CancelableAction { }
            """

        return [syntax.cast(ExtensionDeclSyntax.self)]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: Syntax(node),
                message: SimpleDiagnostic(message: "`@CancelableAction` can only be applied to enums.")
            ))
            return []
        }

        let caseNames = enumDecl.memberBlock.members.compactMap { member -> String? in
            guard let enumCase = member.decl.as(EnumCaseDeclSyntax.self),
                  let firstCase = enumCase.elements.first
            else {
                return nil
            }
            return firstCase.name.text
        }

        let cases = caseNames
            .map { "case .\($0): return \"cancelID/\($0)\"" }
            .joined(separator: "\n        ")

        let cancelIDDecl = """
        var cancelID: String {
            switch self {
                \(cases)
            }
        }
        """

        return [DeclSyntax(stringLiteral: cancelIDDecl)]
    }
}

struct SimpleDiagnostic: DiagnosticMessage {
    let message: String
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID { MessageID(domain: "CancelableActionMacro", id: message) }
}


// MARK: - CompilerPlugin
@main
struct DufapPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CancelableActionMacro.self
        ViewStateActionMacro.self,
        ViewModelMacro.self,
    ]
}

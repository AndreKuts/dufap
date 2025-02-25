import SwiftCompilerPlugin
import SwiftSyntaxMacros

// MARK: - CompilerPlugin
@main
struct DufapPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ActionMacro.self,
        ViewStateActionMacro.self,
        ViewModelMacro.self,
    ]
}

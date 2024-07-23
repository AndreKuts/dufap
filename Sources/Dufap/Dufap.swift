// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(extension, conformances: ViewProtocol)
@attached(member, names: named(viewModel), named(init))
public macro ViewWith<S: StateProtocol, A: ActionProtocol>(state: S.Type, action: A.Type) = #externalMacro(module: "DufapMacros", type: "ViewStateActionMacro")

@attached(extension, conformances: ViewModelProtocol)
@attached(member, names: named(updateStateQueue))
@attached(memberAttribute)
public macro ViewModel() = #externalMacro(module: "DufapMacros", type: "ViewModelMacro")

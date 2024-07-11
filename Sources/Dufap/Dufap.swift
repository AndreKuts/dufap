// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(extension, conformances: ViewProtocol, StateProtocol)
@attached(
    member,
    names: 
        named(viewModel),
        named(init)
)
@attached(memberAttribute)
public macro ViewWith<S: StateProtocol, A: ActionProtocol>(state: S.Type, action: A.Type) = #externalMacro(module: "DufapMacros", type: "ViewStateActionMacro")

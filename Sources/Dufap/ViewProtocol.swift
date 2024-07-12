import SwiftUI

public protocol ViewProtocol where Self: View {

    associatedtype State: StateProtocol
    associatedtype Action: ActionProtocol

    var viewModel: AnyViewModel<State, Action> { get }

    init(viewModel: AnyViewModel<State, Action>)
}

public extension ViewProtocol {

    init<V: ViewModelProtocol>(viewModel: V) where V.Action == Action, V.State == State {
        self.init(viewModel: AnyViewModel(viewModel))
    }
}

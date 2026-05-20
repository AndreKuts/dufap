import Dufap
import SwiftUI

struct CounterState: StateProtocol {
    var count = 0
}

@Action
enum CounterAction {
    case increment
    case decrement
}

@ViewModel(action: CounterAction.self)
final class CounterViewModel {
    var state = CounterState()

    func trigger(action: CounterAction.SyncAction) {
        switch action {
        case .increment:
            state.count += 1
        case .decrement:
            state.count -= 1
        }
    }
}

@ViewWith(state: CounterState.self, action: CounterAction.self)
struct CounterExampleView: View {
    @ObservedObject var viewModel: AnyViewModel<CounterState, CounterAction>

    init(_ viewModel: AnyViewModel<CounterState, CounterAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack {
            Button("-") { viewModel.trigger(action: .decrement) }
            Text("\(viewModel.count)")
            Button("+") { viewModel.trigger(action: .increment) }
        }
    }
}


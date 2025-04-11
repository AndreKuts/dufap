import Dufap
import SwiftUI

struct StateView: StateProtocol {
	let name = "Default Name"
	var incr = 0
}

@Action
enum ActionView {
    case start
    case moreSync
	case updateIncr(Int)
    case moreAsync([Int])
    case oneMOREAsync
    case funcCase
    case viewAll
    case dict
}

@ViewModel(action: ActionView.self)
class ViewMoo {

    var state: StateView

	init(state: StateView = StateView()) {
		self.state = state
	}

    func trigger(action: ActionView.SA) async {
        switch action {
        case .dict:
            print("Async")
        case .funcCase:
            print("Async")
        case .moreAsync(_):
            print("Async")
        case .moreSync:
            print("Async")
        case .oneMOREAsync:
            print("Async")
        case .start:
            print("Async")
        case .updateIncr(_):
            print("Async")
        case .viewAll:
            print("Async")
        }
    }
}

@ViewWith(state: StateView.self, action: ActionView.self)
struct SomeView: View {

    @ObservedObject
    var viewModel: AnyViewModel<StateView, ActionView>

    init(_ viewModel: AnyViewModel<StateView, ActionView>) {
        self.viewModel = viewModel
    }

	var body: some View {
		Text("viewModel.name")
			.onAppear {
				fromDifferentThreadsUpdateState()
			}
	}

	func fromDifferentThreadsUpdateState() {

        DispatchQueue.global().async {
            for i in 0...100000 {
                viewModel.trigger(action: .updateIncr(i))
			}
		}

        DispatchQueue.global().async {
            for i in 0...100000 {
				viewModel.trigger(action: .updateIncr(i))
			}
		}

        DispatchQueue.global().async {
            for i in 0...100000 {
				viewModel.trigger(action: .updateIncr(i))
			}
		}

        DispatchQueue.main.async {
            for i in 0...100000 {
				viewModel.trigger(action: .updateIncr(i))
			}
		}
	}
}

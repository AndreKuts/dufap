import Dufap
import SwiftUI

@Pathable(.value)
enum NavigationRoute {
    case home
    case details(id: String)
}

struct NavigationExampleState: StateProtocol {
    var path: [NavigationRoute] = []
}

@Action
enum NavigationExampleAction {
    case pathChanged([NavigationRoute])
    case openDetails(String)
    case pop
}

@ViewModel(action: NavigationExampleAction.self)
final class NavigationExampleViewModel {
    var state = NavigationExampleState()

    func trigger(action: NavigationExampleAction.SyncAction) {
        switch action {
        case .pathChanged(let path):
            state.path = path
        case .openDetails(let id):
            state.path.append(.details(id: id))
        case .pop:
            _ = state.path.popLast()
        }
    }
}

@ViewWith(state: NavigationExampleState.self, action: NavigationExampleAction.self)
struct NavigationExampleView: View {
    @ObservedObject var viewModel: AnyViewModel<NavigationExampleState, NavigationExampleAction>

    init(_ viewModel: AnyViewModel<NavigationExampleState, NavigationExampleAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: viewModel.binding(\.path, onChange: NavigationExampleAction.pathChanged)) {
            Button("Open Details") {
                viewModel.trigger(action: .openDetails(UUID().uuidString))
            }
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .home:
                    Text("Home")
                case .details(let id):
                    Text(id)
                }
            }
        }
    }
}

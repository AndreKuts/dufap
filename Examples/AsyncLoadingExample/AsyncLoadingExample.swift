import Dufap
import SwiftUI

struct AsyncLoadingState: StateProtocol {
    var isLoading = false
    var title = "Ready"
}

@Action
enum AsyncLoadingAction {
    case refresh

    var triggerMode: TriggerMode {
        switch self {
        case .refresh:
            return .async
        }
    }
}

struct AsyncLoadingService {
    func loadTitle() async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        return "Loaded"
    }
}

@ViewModel(action: AsyncLoadingAction.self)
final class AsyncLoadingViewModel {
    var state = AsyncLoadingState()
    private let service = AsyncLoadingService()

    func triggerAsync(action: AsyncLoadingAction.AsyncAction) async {
        switch action {
        case .refresh:
            state.isLoading = true

            do {
                let title = try await service.loadTitle()
                guard !Task.isCancelled else { return }
                state.title = title
                state.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                state.title = "Failed"
                state.isLoading = false
            }
        }
    }
}

@ViewWith(state: AsyncLoadingState.self, action: AsyncLoadingAction.self)
struct AsyncLoadingExampleView: View {
    @ObservedObject var viewModel: AnyViewModel<AsyncLoadingState, AsyncLoadingAction>

    init(_ viewModel: AnyViewModel<AsyncLoadingState, AsyncLoadingAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text(viewModel.title)
            Button("Refresh") { viewModel.trigger(action: .refresh) }
                .disabled(viewModel.isLoading)
        }
    }
}

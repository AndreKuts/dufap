import Dufap
import SwiftUI

struct LoginExampleState: StateProtocol {
    var email = ""
    var password = ""
    var isSubmitEnabled = false
}

@Action
enum LoginExampleAction {
    case emailChanged(String)
    case passwordChanged(String)
    case submitTapped
}

extension LoginExampleAction: LoggableAction {
    var logDescription: String {
        switch self {
        case .emailChanged(let email):
            return "emailChanged(\(PrivacyMask.email(email)))"
        case .passwordChanged(let password):
            return "passwordChanged(\(PrivacyMask.password(password)))"
        case .submitTapped:
            return "submitTapped"
        }
    }
}

@ViewModel(action: LoginExampleAction.self)
final class LoginExampleViewModel {
    var state = LoginExampleState()

    func trigger(action: LoginExampleAction.SyncAction) {
        switch action {
        case .emailChanged(let email):
            state.email = email
        case .passwordChanged(let password):
            state.password = password
        case .submitTapped:
            break
        }

        state.isSubmitEnabled = state.email.contains("@") && state.password.count >= 8
    }
}

@ViewWith(state: LoginExampleState.self, action: LoginExampleAction.self)
struct LoginExampleView: View {
    @ObservedObject var viewModel: AnyViewModel<LoginExampleState, LoginExampleAction>

    init(_ viewModel: AnyViewModel<LoginExampleState, LoginExampleAction>) {
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            TextField("Email", text: viewModel.binding(\.email, onChange: LoginExampleAction.emailChanged))
            SecureField("Password", text: viewModel.binding(\.password, onChange: LoginExampleAction.passwordChanged))
            Button("Sign In") { viewModel.trigger(action: .submitTapped) }
                .disabled(!viewModel.isSubmitEnabled)
        }
    }
}


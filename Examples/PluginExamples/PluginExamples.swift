import Dufap
import Foundation

enum Analytics {
    static func track(_ name: String) {
        print("track:", name)
    }
}

@Action
enum AuthPluginAction {
    case inputEmail(String)
    case inputPassword(String)
    case login
}

extension AuthPluginAction: LoggableAction {
    var logDescription: String {
        switch self {
        case .inputEmail(let email):
            return "inputEmail(\(PrivacyMask.email(email)))"
        case .inputPassword(let password):
            return "inputPassword(\(PrivacyMask.password(password)))"
        case .login:
            return "login"
        }
    }
}

final class AnalyticsActionPlugin: ActionPlugin {
    func willTrigger(action: any ActionProtocol) { }

    func didTrigger(action: any ActionProtocol) {
        switch action {
        case is AuthPluginAction:
            Analytics.track("auth_action_completed")
        default:
            break
        }
    }
}

func configurePlugins() {
    ActionPluginRegistry.register(
        LoggerActionPlugin(
            logsWillTrigger: false,
            asyncOutput: true
        )
    )

    ActionPluginRegistry.register(AnalyticsActionPlugin())
    ActionPluginRegistry.register(ActionTracer(limit: 100))
}

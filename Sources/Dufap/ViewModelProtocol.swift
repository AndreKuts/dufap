import Combine

public protocol ViewModelProtocol: UpdateStateProtection, ObservableObject where ObjectWillChangePublisher.Output == Void {

    associatedtype Action: ActionProtocol

    func trigger(action: Action)
}

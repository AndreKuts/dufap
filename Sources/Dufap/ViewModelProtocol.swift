import Combine

public protocol ViewModelProtocol: ProtectedStateHolder, ObservableObject where ObjectWillChangePublisher.Output == Void {

    associatedtype Action: ActionProtocol

    func trigger(action: Action)
}

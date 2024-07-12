import Combine

public protocol ViewModelProtocol: ObservableObject where ObjectWillChangePublisher.Output == Void {

    associatedtype Action: ActionProtocol
    associatedtype State: StateProtocol

    var state: State { get }

    func trigger(action: Action)
}

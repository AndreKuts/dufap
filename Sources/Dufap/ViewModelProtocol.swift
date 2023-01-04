import Combine

public protocol ViewModelProtocol: StateProvider, ActionProvider, ObservableObject where ObjectWillChangePublisher.Output == Void {}

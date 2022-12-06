import Combine

public struct Dufap {
}

public protocol ViewModel: StateContainable, ActionContainable, ObservableObject where ObjectWillChangePublisher.Output == Void { }

public protocol AppStore: StateContainable, ActionContainable, ObservableObject where ObjectWillChangePublisher.Output == Void { }

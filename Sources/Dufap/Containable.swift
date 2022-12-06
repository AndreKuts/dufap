import Combine

public protocol StateContainable {
	associatedtype State
	var state: State { get }
}

public protocol ActionContainable {
	associatedtype Action
	func trigger(action: Action)
}

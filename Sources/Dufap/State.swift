public protocol StateProtocol { }

public protocol StateProvider {

	associatedtype State: StateProtocol

	var state: State { get }

}

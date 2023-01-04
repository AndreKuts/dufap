public protocol ActionProtocol { }

public protocol ActionProvider {

	associatedtype Action: ActionProtocol

	func trigger(action: Action)

}

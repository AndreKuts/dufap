import Combine

@dynamicMemberLookup
open class AnyViewModel<State: StateProtocol, Action: ActionProtocol>: ViewModelProtocol {

	private let wrappedObjectWillChange: () -> AnyPublisher<Void, Never>
	private let wrappedState: () -> State
	private let wrappedTrigger: (Action) -> Void

	public var objectWillChange: AnyPublisher<Void, Never> { wrappedObjectWillChange() }
	public var state: State { wrappedState() }

	public init<V: ViewModelProtocol>(_ viewModel: V) where V.State == State, V.Action == Action {
		self.wrappedObjectWillChange = { viewModel.objectWillChange.eraseToAnyPublisher() }
		self.wrappedState = { viewModel.state }
		self.wrappedTrigger = viewModel.trigger
	}

	public func trigger(action: Action) {
		wrappedTrigger(action)
	}

	public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
		state[keyPath: keyPath]
	}
}

extension AnyViewModel: Identifiable where State: Identifiable {
	public var id: State.ID { state.id }
}

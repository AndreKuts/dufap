import Foundation

public protocol ProtectedStateHolder: AnyObject {

    associatedtype State: StateProtocol

    var state: State { get set }

    /// This is a queue for state  sync update
    var updateStateQueue: DispatchQueue { get }
}

public extension ProtectedStateHolder {

    /// Sync state update function
    ///   - `completion` is a save place for updating State
    func updateState(completion: @escaping (inout State) -> Void) {
        updateStateQueue.sync {
            completion(&state)
        }
    }
}

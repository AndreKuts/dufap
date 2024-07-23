import Foundation

public protocol UpdateStateProtection: AnyObject {

    associatedtype State: StateProtocol

    var state: State { get set }
    var updateStateQueue: DispatchQueue { get }

    func updateState(completion: @escaping (inout State) -> Void)
}

public extension UpdateStateProtection {

    func updateState(completion: @escaping (inout State) -> Void) {
        updateStateQueue.sync {
            completion(&state)
        }
    }
}

import Foundation

public protocol UpdateStateProtection: AnyObject {

    associatedtype State: StateProtocol

    var state: State { get set }
    var setStateLock: NSLock { get }

    func updateState(completion: @escaping (inout State) -> Void)
}

public extension UpdateStateProtection {

    func updateState(completion: @escaping (inout State) -> Void) {
        if Thread.isMainThread {
            completion(&state)
        } else {
            setStateLock.lock()
            completion(&state)
            setStateLock.unlock()
        }
    }
}

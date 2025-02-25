import Combine
import Foundation

public final class CancellableBag<CancelID: Hashable> {

    private var bag: [CancelID: Any] = [:]

    public init() {}

    @discardableResult
    public func cancel(id: CancelID) -> Any? {

        guard let value = bag.removeValue(forKey: id) else {
            return nil
        }

        if let cancellable = value as? AnyCancellable {
            cancellable.cancel()
        } else

        if let observer = value as? NSKeyValueObservation {
            observer.invalidate()
        }

        return value
    }

    public func cancelAll() {
        bag.forEach { key, _ in
            cancel(id: key)
        }
    }

    public func add(id: CancelID, _ any: Any?) {
        cancel(id: id)
        bag[id] = any
    }
}

public extension Task {
    func store<ID: Hashable>(in bag: CancellableBag<ID>, as id: ID) {
        bag.add(id: id, AnyCancellable(cancel))
    }
}

public extension AnyCancellable {
    func store<ID: Hashable>(in bag: CancellableBag<ID>, as id: ID) {
        bag.add(id: id, self)
    }
}

public extension NSKeyValueObservation {
    func store<ID: Hashable>(in bag: CancellableBag<ID>, as id: ID) {
        bag.add(id: id, self)
    }
}

public extension NSObjectProtocol {
    func store<ID: Hashable>(in bag: CancellableBag<ID>, as id: ID) {
        bag.add(id: id, self)
    }
}

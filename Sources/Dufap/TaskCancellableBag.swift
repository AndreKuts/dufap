import Combine

public final class CancellableBag<CancelID: Hashable> {

    /// Storage for `AnyCancellable` objects, indexed by an ID.
    private var bag: [CancelID: AnyCancellable] = [:]

    public init() {}

    /// Cancels and removes the task associated with the specified `id`.
    /// - Parameter id: The identifier of the task to cancel.
    public func cancel(id: CancelID) {
        bag[id]?.cancel()
        bag.removeValue(forKey: id)
    }

    /// Cancels and removes all tasks in the bag.
    public func cancelAll() {
        bag.values.forEach { $0.cancel() }
        bag.removeAll()
    }

    /// Adds a cancellable task to the bag, replacing any existing task with the same ID.
    /// - Parameters:
    ///   - id: The identifier for the task.
    ///   - cancellable: The `AnyCancellable` task to add.
    public func add(id: CancelID, cancellable: AnyCancellable) {
        bag[id]?.cancel()
        bag[id] = cancellable
    }

    /// Accesses the `AnyCancellable` associated with a given ID for reading and writing.
    /// - Parameter id: The identifier of the task to access.
    /// - Returns: The `AnyCancellable` associated with the ID, or `nil` if it doesn't exist.
    public subscript(id: CancelID) -> AnyCancellable? {
        get {
            bag[id]
        }
        set {
            if let newValue = newValue {
                bag[id] = newValue
            } else {
                bag.removeValue(forKey: id)
            }
        }
    }
}

public extension Task {

    /// Stores the task's cancellation token in a `CancellableBag` with a unique identifier.
    /// - Parameters:
    ///   - bag: The `CancellableBag` where the cancellation token will be stored.
    ///   - id: The identifier used to associate the task's cancellation token within the bag.
    func store<ID: Hashable>(in bag: CancellableBag<ID>, as id: ID) {
        bag.add(id: id, cancellable: AnyCancellable(cancel))
    }
}

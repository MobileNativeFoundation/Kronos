import os.lock

final class UnfairLock {
    private let lockPointer: os_unfair_lock_t

    init() {
        self.lockPointer = .allocate(capacity: 1)
        self.lockPointer.initialize(to: os_unfair_lock())
    }

    deinit {
        self.lockPointer.deinitialize(count: 1)
        self.lockPointer.deallocate()
    }

    func lock() {
        os_unfair_lock_lock(self.lockPointer)
    }

    func unlock() {
        os_unfair_lock_unlock(self.lockPointer)
    }

    func synchronized<T>(_ block: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return block()
    }
}

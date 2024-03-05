import Foundation

/// Dedicated version of `Clock` type for Prex service with proper protection against to concurrent access.
/// - Internal implementation of `NTPClient` must be used only from main thread. See the code for details.
/// - This is a concurrency protection layer.
///
///
/// High level implementation for clock synchronization using NTP. All returned dates use the most accurate
/// synchronization and it's not affected by clock changes. The NTP synchronization implementation has sub-
/// second accuracy but given that Darwin doesn't support microseconds on bootTime, dates don't have sub-
/// second accuracy.
///
/// Example usage:
///
/// ```swift
/// Clock.sync { date, offset in
///     print(date)
/// }
/// // (... later on ...)
/// print(Clock.now)
/// ```
public enum Clock2 {
    /// Syncs the clock using NTP. Note that the full synchronization could take a few seconds. The given
    /// closure will be called with the first valid NTP response which accuracy should be good enough for the
    /// initial clock adjustment but it might not be the most accurate representation. After calling the
    /// closure this method will continue syncing with multiple servers and multiple passes.
    /// - parameter completion:
    ///     A closure that will be called after _all_ the NTP calls are finished.
    ///     This will be called from main thread.
    @MainActor
    public static func sync(completion: SyncCallback? = nil) {
        assert(Thread.isMainThread)
        let defaultPool = "time.apple.com"
        let defaultSampleCount = 4
        sync(from: defaultPool, samples: defaultSampleCount, completion: completion)
    }
    public typealias SyncCallback = (TimeInterval?) -> Void
    
//    @MainActor
//    public static func synchronizeTimeWithNTPServers() async {
//        let checkpoint = PrexCheckpoint()
//        sync { _ in
//            /// ...
//            checkpoint.signal()
//        }
//        await checkpoint.wait()
//    }
    
    /// Resets all state of the monotonic clock. Note that you won't be able to access `now` until you `sync`
    /// again.
    @MainActor
    public static func reset() {
        assert(Thread.isMainThread)
        protection.lock()
        latestOffset = nil
        protection.unlock()
    }

    /// Offset between local clock and real-world NTP clock.
    /// - Note: 
    ///     This function is thread-safe. Can be called from any thread concurrently.
    ///     This is mainly provided to support storing/restoring of clock state.
    public static var offset: TimeInterval? {
        get {
            protection.lock()
            let localCopy = latestOffset
            protection.unlock()
            return localCopy
        }
        set {
            protection.lock()
            latestOffset = newValue
            protection.unlock()
        }
    }
    
    /// The most accurate date that we have so far (nil if no synchronization was done yet)
    ///
    /// - Note: This function is thread-safe. Can be called from any thread concurrently.
    public static var now: Date? {
        protection.lock()
        let localCopy = latestOffset
        protection.unlock()
        guard let latestOffset = localCopy else { return nil }
        return Date(timeIntervalSince1970: TimeFreeze(offset: latestOffset).adjustedTimestamp)
    }
    
    
    /// Determines where the most current stable time is stored. Use TimeStoragePolicy.appGroup to share
    /// between your app and an extension.
    private static var latestOffset: TimeInterval?
    private static let protection = NSLock()

    /// Syncs the clock using NTP. Note that the full synchronization could take a few seconds. The given
    /// closure will be called with the first valid NTP response which accuracy should be good enough for the
    /// initial clock adjustment but it might not be the most accurate representation. After calling the
    /// closure this method will continue syncing with multiple servers and multiple passes.
    ///
    /// - parameter pool:       NTP pool that will be resolved into multiple NTP servers that will be used for
    ///                         the synchronization.
    /// - parameter samples:    The number of samples to be acquired from each server.
    /// - parameter completion: A closure that will be called after _all_ the NTP calls are finished.
    @MainActor
    private static func sync(
        from pool: String,
        samples: Int,
        completion: ((TimeInterval?) -> Void)? = nil)
    {
        assert(Thread.isMainThread)
        NTPClient().query(pool: pool, numberOfSamples: samples) { offset, done, total in
            assert(Thread.isMainThread)
            if let offset = offset {
                protection.lock()
                latestOffset = offset
                protection.unlock()
            }
            
            if done == total {
                completion?(offset)
            }
        }
    }
}

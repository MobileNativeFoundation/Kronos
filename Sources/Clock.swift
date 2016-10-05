import Foundation

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
/// print(Clock.date)
/// ```
public struct Clock {

    private static var stableTime: TimeFreeze?

    /// The most accurate timestamp that we have so far (nil if no synchronization was done yet)
    public static var timestamp: TimeInterval? {
        return self.stableTime?.adjustedTimestamp
    }

    /// The most accurate date that we have so far (nil if no synchronization was done yet)
    public static var now: Date? {
        return self.timestamp.map { Date(timeIntervalSince1970: $0) }
    }

    /// Syncs the clock using NTP. Note that the full synchronization could take a few seconds. The given
    /// closure will be called with the first valid NTP response which accuracy should be good enough for the
    /// initial clock adjustment but it might not be the most accurate representation. After calling the
    /// closure this method will continue syncing with multiple servers and multiple passes.
    ///
    /// - parameter pool:       NTP pool that will be resolved into multiple NTP servers that will be used for
    ///                         the synchronization.
    /// - parameter samples:    The number of samples to be acquired from each server (default 4).
    /// - parameter completion: A closure that will be called after _all_ the NTP calls are finished.
    /// - parameter first:      A closure that will be called after the first valid date is calculated.
    public static func sync(from pool: String = "time.apple.com", samples: Int = 4,
                            first: ((Date, TimeInterval) -> Void)? = nil,
                            completion: ((Date?, TimeInterval?) -> Void)? = nil)
    {
        self.reset()

        NTPClient().query(pool: pool, numberOfSamples: samples) { offset, done, total in
            if let offset = offset {
                self.stableTime = TimeFreeze(offset: offset)

                if done == 1, let now = self.now {
                    first?(now, offset)
                }
            }

            if done == total {
                completion?(self.now, offset)
            }
        }
    }

    /// Resets all state of the monotonic clock. Note that you won't be able to access `now` until you `sync`
    /// again.
    public static func reset() {
        self.stableTime = nil
    }
}

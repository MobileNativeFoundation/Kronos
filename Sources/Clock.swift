import Foundation

/// Struct that has time + related metadata
public struct FullTime {
    /// The most accurate timetstamp that we have so far
    let date: Date

    /// Amount of time that has passed since the last NTP sync; in other words, the NTP response age.
    /// If the NTP response is one deserialized from disk, and we notice the phone has been rebooted since
    /// serialization time, we can't know how old the response is, since we use the time-since-boot to measure
    /// duration. Thus, in this case, this value will be nil.
    let timeSinceLastNtpSync: TimeInterval?
}

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
public struct Clock {
    private static var stableTime: TimeFreeze? {
        didSet {
            self.storage.stableTime = self.stableTime
        }
    }

    /// Determines where the most current stable time is stored. Use TimeStoragePolicy.appGroup to share
    /// between your app and an extension.
    public static var storage = TimeStorage(storagePolicy: .standard)

    /// The most accurate timestamp that we have so far (nil if no synchronization was done yet)
    public static var timestamp: TimeInterval? {
        return self.stableTime?.adjustedTimestamp
    }

    /// The most accurate date that we have so far (nil if no synchronization was done yet)
    public static var now: Date? {
        return self.fullNow?.date
    }

    public static var fullNow: FullTime? {
        return self.stableTime?.fullTime
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
        self.loadFromDefaults()

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

    private static func loadFromDefaults() {
        guard let previousStableTime = self.storage.stableTime else {
            self.stableTime = nil
            return
        }
        self.stableTime = previousStableTime
    }
}

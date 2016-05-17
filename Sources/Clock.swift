import Foundation

/**
 High level implementation for clock synchronization using NTP. All returned dates use the most accurate 
 synchronization and it's not affected by clock changes. The NTP synchronization implementation has
 sub-second accuracy but given that Darwin doesn't support microseconds on bootTime, dates don't have 
 sub-second accuracy.

 Example usage:

 ```swift
 Clock.sync { date in
    print(date)
 }

 // (... later on ...)
 print(Clock.date)
 ```
 */
public struct Clock {

    private static var uptimeOnLastSync: NSTimeInterval?
    private static var timestampOnLastSync: NSTimeInterval?

    /// The most accurate timestamp that we have so far (nil if no synchronization was done yet)
    public static var timestamp: NSTimeInterval? {
        guard let lastUptime = self.uptimeOnLastSync, lastTimestamp = self.timestampOnLastSync else {
            return nil
        }

        return (self.systemUptime() - lastUptime) + lastTimestamp
    }

    /// The most accurate date that we have so far (nil if no synchronization was done yet)
    public static var now: NSDate? {
        return self.timestamp.map { NSDate(timeIntervalSince1970: $0) }
    }

    /**
     Syncs the clock using NTP. Note that the full synchronization could take a few seconds. The given closure 
     will be called with the first valid NTP response which accuracy should be good enough for the initial 
     clock adjustment but it might not be the most accurate representation. After calling the closure this 
     method will continue syncing with multiple servers and multiple passes.

     - parameter pool:    NTP pool that will be resolved into multiple NTP servers that will be used
                          for the synchronization.
     - parameter samples: The number of samples to be acquired from each server (default 4).
     - parameter first:   A closure that will be called after the first valid date is calculated.
     */
    public static func sync(from pool: String = "time.apple.com", samples: Int = 4,
                            first: ((date: NSDate, offset: NSTimeInterval) -> Void)? = nil)
    {
        var isFirstResult = true
        NTPClient().queryPool(pool, numberOfSamples: samples) { offset in
            var now = timeval()
            guard let offset = offset where gettimeofday(&now, nil) == 0 else {
                return
            }

            self.uptimeOnLastSync = self.systemUptime()

            let (integerOffset, fractionalOffset) = modf(offset)
            let microseconds = (Double(now.tv_usec) + fractionalOffset) / 1_000_000
            self.timestampOnLastSync = (Double(now.tv_sec) + integerOffset) + microseconds

            if isFirstResult, let now = self.now {
                isFirstResult = false
                first?(date: now, offset: offset)
            }
        }
    }

    /**
     Returns a high-resolution measurement of system uptime, that continues ticking
     through device sleep *and* user- or system-generated clock adjustments. This
     allows for stable differences to be calculated between timestamps.

     Note: Due to an issue in BSD/darwin, sub-second precision will be lost; see:
           https://github.com/darwin-on-arm/xnu/blob/master/osfmk/kern/clock.c#L522

     - returns: an Int measurement of system uptime in microseconds.
     */
    public static func systemUptime() -> NSTimeInterval {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = strideof(timeval)
        var bootTime = timeval()
        var now = timeval()

        let systemTimeError = gettimeofday(&now, nil) != 0
        assert(!systemTimeError, "system clock error: system time unavailable")

        let bootTimeError = sysctl(&mib, u_int(mib.count), &bootTime, &size, nil, 0) != 0
        assert(!bootTimeError, "system clock error: kernel boot time unavailable")

        let seconds = Double(now.tv_sec - bootTime.tv_sec)
        assert(now.tv_sec >= bootTime.tv_sec, "inconsistent clock state: system time precedes boot time")

        // boottime.tv_usec is actually always 0 on darwin systems
        let microseconds = Double(now.tv_usec - bootTime.tv_usec) / 1_000_000
        return seconds + microseconds
    }

    /**
     Resets all clock synchronization information
     */
    public static func reset() {
        self.uptimeOnLastSync = nil
        self.timestampOnLastSync = nil
    }
}
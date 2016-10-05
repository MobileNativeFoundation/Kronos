import Foundation

struct TimeFreeze {
    private let uptime: TimeInterval
    private let timestamp: TimeInterval
    private let offset: TimeInterval

    /// The stable timestamp adjusted by the most acurrate offset known so far.
    var adjustedTimestamp: TimeInterval? {
        return self.offset + self.stableTimestamp
    }

    /// The stable timestamp (calculated based on the uptime); note that this doesn't have sub-seconds
    /// precision. See `systemUptime()` for more information.
    var stableTimestamp: TimeInterval {
        return (TimeFreeze.systemUptime() - self.uptime) + self.timestamp
    }

    init(offset: TimeInterval) {
        self.offset = offset
        self.timestamp = currentTime()
        self.uptime = TimeFreeze.systemUptime()
    }

    /// Returns a high-resolution measurement of system uptime, that continues ticking through device sleep
    /// *and* user- or system-generated clock adjustments. This allows for stable differences to be calculated
    /// between timestamps.
    ///
    /// Note: Due to an issue in BSD/darwin, sub-second precision will be lost;
    /// see: https://github.com/darwin-on-arm/xnu/blob/master/osfmk/kern/clock.c#L522.
    ///
    /// - returns: An Int measurement of system uptime in microseconds.
    static func systemUptime() -> TimeInterval {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout<timeval>.stride
        var bootTime = timeval()

        let bootTimeError = sysctl(&mib, u_int(mib.count), &bootTime, &size, nil, 0) != 0
        assert(!bootTimeError, "system clock error: kernel boot time unavailable")

        let now = currentTime()
        let uptime = Double(bootTime.tv_sec) + Double(bootTime.tv_usec) / 1_000_000
        assert(now >= uptime, "inconsistent clock state: system time precedes boot time")

        return now - uptime
    }
}

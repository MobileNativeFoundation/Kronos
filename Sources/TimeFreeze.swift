import Foundation

struct TimeFreeze {
    private let uptime: NSTimeInterval
    private let timestamp: NSTimeInterval
    private let offset: NSTimeInterval

    var adjustedTimestamp: NSTimeInterval? {
        return self.offset + self.stableTimestamp
    }

    var stableTimestamp: NSTimeInterval {
        return (TimeFreeze.systemUptime() - self.uptime) + self.timestamp
    }

    init(offset: NSTimeInterval) {
        var current = timeval()
        let systemTimeError = gettimeofday(&current, nil) != 0
        assert(!systemTimeError, "system clock error: system time unavailable")

        self.offset = offset
        self.timestamp = Double(current.tv_sec) + 1_000_000 * Double(current.tv_usec)
        self.uptime = TimeFreeze.systemUptime()
    }

    /**
     Returns a high-resolution measurement of system uptime, that continues ticking
     through device sleep *and* user- or system-generated clock adjustments. This
     allows for stable differences to be calculated between timestamps.

     Note: Due to an issue in BSD/darwin, sub-second precision will be lost; see:
           https://github.com/darwin-on-arm/xnu/blob/master/osfmk/kern/clock.c#L522

     - returns: an Int measurement of system uptime in microseconds.
     */
    static func systemUptime() -> NSTimeInterval {
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
}

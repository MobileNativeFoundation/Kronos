import Foundation

typealias CKTimerHandler = (timer: NSTimer) -> Void

/// Simple closure implementation on NSTimer scheduling.
///
/// Example:
///
/// ```swift
/// BlockTimer.scheduledTimerWithTimeInterval(1.0) { timer in
///     println("Did something after 1s!")
/// }
/// ```
final class BlockTimer: NSObject {

    /// Creates and returns a block-based NSTimer object and schedules it on the current run loop.
    ///
    /// - parameter interval: The number of seconds between firings of the timer.
    /// - parameter repeated: If true, the timer will repeatedly reschedule itself until invalidated. If
    ///                       false, the timer will be invalidated after it fires.
    /// - parameter handler:  The closure that the NSTimer fires.
    ///
    /// - returns: A new NSTimer object, configured according to the specified parameters.
    class func scheduledTimerWithTimeInterval(interval: NSTimeInterval, repeated: Bool = false,
        handler: CKTimerHandler) -> NSTimer
    {
        return NSTimer.scheduledTimerWithTimeInterval(interval, target: self,
            selector: #selector(BlockTimer.invokeFromTimer(_:)),
            userInfo: TimerClosureWrapper(handler: handler, repeats: repeated), repeats: repeated)
    }

    // MARK: Private methods

    @objc
    class private func invokeFromTimer(timer: NSTimer) {
        if let closureWrapper = timer.userInfo as? TimerClosureWrapper {
            closureWrapper.handler(timer: timer)
        }
    }
}

// MARK: - Private classes

private final class TimerClosureWrapper {
    private var handler: CKTimerHandler
    private var repeats: Bool

    init(handler: CKTimerHandler, repeats: Bool) {
        self.handler = handler
        self.repeats = repeats
    }
}

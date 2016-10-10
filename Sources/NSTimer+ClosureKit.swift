import Foundation

typealias CKTimerHandler = (Timer) -> Void

/// Simple closure implementation on NSTimer scheduling.
///
/// Example:
///
/// ```swift
/// BlockTimer.scheduledTimer(withTimeInterval: 1.0) { timer in
///     print("Did something after 1s!")
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
    class func scheduledTimer(withTimeInterval interval: TimeInterval, repeated: Bool = false,
        handler: @escaping CKTimerHandler) -> Timer
    {
        return Timer.scheduledTimer(timeInterval: interval, target: self,
            selector: #selector(BlockTimer.invokeFrom(timer:)),
            userInfo: TimerClosureWrapper(handler: handler, repeats: repeated), repeats: repeated)
    }

    // MARK: Private methods

    @objc
    class private func invokeFrom(timer: Timer) {
        if let closureWrapper = timer.userInfo as? TimerClosureWrapper {
            closureWrapper.handler(timer)
        }
    }
}

// MARK: - Private classes

private final class TimerClosureWrapper {
    fileprivate var handler: CKTimerHandler
    private var repeats: Bool

    init(handler: @escaping CKTimerHandler, repeats: Bool) {
        self.handler = handler
        self.repeats = repeats
    }
}

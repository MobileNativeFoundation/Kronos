//
//  NSTimer+ClosureKit.swift
//  Created by Martin Conte Mac Donell on 3/31/15.
//
//  Copyright (c) 2015 Lyft (http://lyft.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

typealias CKTimerHandler = (timer: NSTimer) -> Void

/**
Simple closure implementation on NSTimer scheduling.

Example:

```swift
NSTimer.scheduledTimerWithTimeInterval(1.0) { timer in
println("Did something after 1s!")
}
```
*/
extension NSTimer {

    /**
    Creates and returns a block-based NSTimer object and schedules it on the current run loop.

    :param: interval  The number of seconds between firings of the timer.
    :param: inRepeats If true, the timer will repeatedly reschedule itself until invalidated. If false,
                      the timer will be invalidated after it fires.
    :param: handler   The closure that the NSTimer fires.

    :returns: a new NSTimer object, configured according to the specified parameters.
    */
    class func scheduledTimerWithTimeInterval(interval: NSTimeInterval, repeats: Bool = false,
        handler: CKTimerHandler) -> NSTimer
    {
        return NSTimer.scheduledTimerWithTimeInterval(interval, target: self,
            selector: #selector(NSTimer.invokeFromTimer(_:)),
            userInfo: TimerClosureWrapper(handler: handler, repeats: repeats), repeats: repeats)
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

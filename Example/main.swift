import Foundation
import Kronos

/**
Executes the given clousure after a delay of "delay" seconds.

- parameter delay:   The delay in seconds.
- parameter closure: A closure that is going to be executed after the delay.
*/
public func executeAfter(delay: Double, closure: () -> Void) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), closure)
}

class ASCIIClock {
    private var timer: NSTimer?

    private func start() {
        print("Waiting for clock sync ...")

        Clock.sync { offset, date in
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self,
                                                                selector: #selector(ASCIIClock.onTick),
                                                                userInfo: nil, repeats: true)
            self.timer?.fire()
        }
    }

    @objc
    private func onTick() {
        print(Clock.date)
    }
}

ASCIIClock().start()

let runLoop = NSRunLoop.currentRunLoop()
while runLoop.runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture()) {}

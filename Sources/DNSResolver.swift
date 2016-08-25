import Foundation

private let kCopyNoOperation = unsafeBitCast(0, CFAllocatorCopyDescriptionCallBack.self)
private let kDefaultTimeout = 8.0

final class DNSResolver {
    private var completion: ([InternetAddress] -> Void)?
    private var timer: NSTimer?

    private init() {}

    /**
     Performs DNS lookups and calls the given completion with the answers that are returned from the name
     server(s) that were queried.

     - parameter host:       The host to be looked up.
     - parameter timeout:    The connection timeout.
     - parameter completion: A completion block that will be called both on failure and success with a list of
                             IPs.
     */
    static func resolve(host host: String, timeout: NSTimeInterval = kDefaultTimeout,
                        completion: [InternetAddress] -> Void)
    {
        let callback: CFHostClientCallBack = { host, hostinfo, error, info in
            let retainedSelf = Unmanaged<DNSResolver>.fromOpaque(COpaquePointer(info))
            let resolver = retainedSelf.takeUnretainedValue()
            resolver.timer?.invalidate()
            resolver.timer = nil

            var resolved: DarwinBoolean = false
            guard let addresses = CFHostGetAddressing(host, &resolved) where resolved else {
                resolver.completion?([])
                retainedSelf.release()
                return
            }

            let IPs = (addresses.takeUnretainedValue() as NSArray)
                .flatMap { $0 as? NSData }
                .flatMap { data -> InternetAddress? in
                    let socketAddress = UnsafePointer<sockaddr_storage>(data.bytes)
                    return InternetAddress(storage: socketAddress)
                }

            resolver.completion?(IPs)
            retainedSelf.release()
        }

        let resolver = DNSResolver()
        resolver.completion = completion

        let retainedClosure = Unmanaged.passRetained(resolver).toOpaque()
        var clientContext = CFHostClientContext(version: 0, info: UnsafeMutablePointer<Void>(retainedClosure),
                                                retain: nil, release: nil, copyDescription: kCopyNoOperation)

        let hostReference = CFHostCreateWithName(kCFAllocatorDefault, host).takeUnretainedValue()
        CFHostSetClient(hostReference, callback, &clientContext)
        CFHostScheduleWithRunLoop(hostReference, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
        CFHostStartInfoResolution(hostReference, .Addresses, nil)

        resolver.timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: resolver,
                                                                selector: #selector(DNSResolver.onTimeout),
                                                                userInfo: hostReference, repeats: false)
    }

    @objc
    private func onTimeout() {
        defer {
            self.completion?([])

            // Manually release the previously retained self.
            Unmanaged.passUnretained(self).release()
        }

        guard let userInfo = self.timer?.userInfo else {
            return
        }

        let hostReference = unsafeBitCast(userInfo, CFHost.self)
        CFHostCancelInfoResolution(hostReference, .Addresses)
        CFHostUnscheduleFromRunLoop(hostReference, CFRunLoopGetCurrent(), kCFRunLoopCommonModes)
        CFHostSetClient(hostReference, nil, nil)
    }
}

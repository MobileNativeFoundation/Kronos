import Foundation

private let kCopyNoOperation = unsafeBitCast(0, to: CFAllocatorCopyDescriptionCallBack.self)
private let kDefaultTimeout = 8.0

final class DNSResolver {
    private var completion: (([InternetAddress]) -> Void)?
    private var timer: Timer?

    private init() {}

    /// Performs DNS lookups and calls the given completion with the answers that are returned from the name
    /// server(s) that were queried.
    ///
    /// - parameter host:       The host to be looked up.
    /// - parameter timeout:    The connection timeout.
    /// - parameter completion: A completion block that will be called both on failure and success with a list
    ///                         of IPs.
    static func resolve(host: String, timeout: TimeInterval = kDefaultTimeout,
                        completion: @escaping ([InternetAddress]) -> Void)
    {
        let callback: CFHostClientCallBack = { host, hostinfo, error, info in
            guard let info = info else {
                return
            }
            let retainedSelf = Unmanaged<DNSResolver>.fromOpaque(info)
            let resolver = retainedSelf.takeUnretainedValue()
            resolver.timer?.invalidate()
            resolver.timer = nil

            var resolved: DarwinBoolean = false
            guard let addresses = CFHostGetAddressing(host, &resolved), resolved.boolValue else {
                resolver.completion?([])
                retainedSelf.release()
                return
            }

            let IPs = (addresses.takeUnretainedValue() as NSArray)
                .flatMap { $0 as? Data }
                .flatMap { data -> InternetAddress? in
                    return data.withUnsafeBytes { (pointer: UnsafePointer<sockaddr_storage>) in
                        return InternetAddress(storage: pointer)
                    }
                }

            resolver.completion?(IPs)
            retainedSelf.release()
        }

        let resolver = DNSResolver()
        resolver.completion = completion

        let retainedClosure = Unmanaged.passRetained(resolver).toOpaque()
        var clientContext = CFHostClientContext(version: 0, info: UnsafeMutableRawPointer(retainedClosure),
                                                retain: nil, release: nil, copyDescription: kCopyNoOperation)

        let hostReference = CFHostCreateWithName(kCFAllocatorDefault, host as CFString).takeUnretainedValue()
        resolver.timer = Timer.scheduledTimer(timeInterval: timeout, target: resolver,
                                              selector: #selector(DNSResolver.onTimeout),
                                              userInfo: hostReference, repeats: false)

        CFHostSetClient(hostReference, callback, &clientContext)
        CFHostScheduleWithRunLoop(hostReference, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
        CFHostStartInfoResolution(hostReference, .addresses, nil)
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

        let hostReference = unsafeBitCast(userInfo as AnyObject, to: CFHost.self)
        CFHostCancelInfoResolution(hostReference, .addresses)
        CFHostUnscheduleFromRunLoop(hostReference, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
        CFHostSetClient(hostReference, nil, nil)
    }
}

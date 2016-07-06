import Foundation

private let kDefaultTimeout = 6.0
private let kDefaultSamples = 4
private let kMaximumNTPServers = 5
private let kMaximumResultDispersion = 10.0

private typealias ObjCCompletionType = @convention(block) (NSData?, NSTimeInterval) -> Void

/**
 Exception raised while sending / receiving NTP packets.
 */
enum NTPNetworkError: ErrorType {
    case NoValidNTPPacketFound
}

/**
 NTP client session.
 */
final class NTPClient {

    /**
     Query the all ips that resolve from the given pool.

     - parameter pool:            NTP pool that will be resolved into multiple NTP servers.
     - parameter port:            Server NTP port (default 123).
     - parameter version:         NTP version to use (default 3).
     - parameter numberOfSamples: The number of samples to be acquired from each server (default 4).
     - parameter timeout:         The individual timeout for each of the NTP operations.
     - parameter completion:      A closure that will be response PDU on success or nil on error.
     */
    func queryPool(pool: String = "time.apple.com", version: Int8 = 3, port: Int = 123,
                   numberOfSamples: Int = kDefaultSamples, timeout: CFTimeInterval = kDefaultTimeout,
                   progress: (offset: NSTimeInterval?, completed: Int, total: Int) -> Void)
    {
        var servers: [String: [NTPPacket]] = [:]
        var completed: Int = 0

        let queryIPAndStoreResult = { (address: String, totalQueries: Int) -> Void in
            self.queryIP(address, port: port, version: version, timeout: timeout,
                         numberOfSamples: numberOfSamples)
            { packet in
                defer {
                    completed += 1

                    let responses = Array(servers.values)
                    progress(offset: try? self.offsetFromResponses(responses),
                             completed: completed, total: totalQueries)
                }

                guard let PDU = packet else {
                    return
                }

                if servers[address] == nil {
                    servers[address] = []
                }

                servers[address]?.append(PDU)
            }
        }

        DNSResolver.resolve(host: pool) { addresses in
            if addresses.count == 0 {
                return progress(offset: nil, completed: 0, total: 0)
            }

            let totalServers = min(addresses.count, kMaximumNTPServers)
            for address in addresses[0 ..< totalServers] {
                queryIPAndStoreResult(address, totalServers * numberOfSamples)
            }
        }
    }

    /**
     Query the given ntp server for the time exchange.

     - parameter ip:              Server socket address.
     - parameter port:            Server NTP port (default 123).
     - parameter version:         NTP version to use (default 3).
     - parameter timeout:         Timeout on socket operations.
     - parameter numberOfSamples: The number of samples to be acquired from the server (default 4).
     - parameter completion:      A closure that will be response PDU on success or nil on error.
     */
    func queryIP(ip: String, port: Int = 123, version: Int8 = 3, timeout: CFTimeInterval = kDefaultTimeout,
                 numberOfSamples: Int = kDefaultSamples, completion: (PDU: NTPPacket?) -> Void)
    {
        var timer: NSTimer? = nil
        let bridgeCallback: ObjCCompletionType = { data, destinationTime in
            defer {
                // If we still have samples left; we'll keep querying the same server
                if numberOfSamples > 1 {
                    self.queryIP(ip, port: port, version: version, timeout: timeout,
                                 numberOfSamples: numberOfSamples - 1, completion: completion)
                }
            }

            timer?.invalidate()
            guard let data = data, PDU = try? NTPPacket(data: data, destinationTime: destinationTime) else {
                return completion(PDU: nil)
            }

            completion(PDU: PDU.isValidResponse() ? PDU : nil)
        }

        let callback = unsafeBitCast(bridgeCallback, AnyObject.self)
        let retainedCallback = Unmanaged.passRetained(callback)
        let sourceAndSocket = self.sendAsyncUDPQuery(
            to: ip, port: port, timeout: timeout,
            completion: UnsafeMutablePointer<Void>(retainedCallback.toOpaque())
        )

        timer = BlockTimer.scheduledTimerWithTimeInterval(timeout) { _ in
            bridgeCallback(nil, NSTimeInterval.infinity)
            retainedCallback.release()

            if let (source, socket) = sourceAndSocket {
                CFSocketInvalidate(socket)
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes)
            }
        }
    }

    // MARK: - Private helpers (NTP Calculation)

    private func offsetFromResponses(responses: [[NTPPacket]]) throws -> NSTimeInterval {
        let now = currentTime()
        var bestResponses: [NTPPacket] = []
        for serverResponses in responses {
            let filtered = serverResponses
                .filter { abs($0.originTime - now) < kMaximumResultDispersion }
                .minElement { $0.delay < $1.delay }

            if let filtered = filtered {
                bestResponses.append(filtered)
            }
        }

        if bestResponses.count == 0 {
            throw NTPNetworkError.NoValidNTPPacketFound
        }

        bestResponses.sortInPlace { $0.offset < $1.offset }
        return bestResponses[bestResponses.count / 2].offset
    }

    // MARK: - Private helpers (CFSocket)

    private func sendAsyncUDPQuery(to ip: String, port: Int, timeout: NSTimeInterval,
                                      completion: UnsafeMutablePointer<Void>) -> (CFRunLoopSource, CFSocket)?
    {
        let callback: CFSocketCallBack = { socket, callbackType, address, data, info in
            if callbackType == .WriteCallBack {
                var packet = NTPPacket()
                let PDU = packet.prepareToSend()
                let data = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(PDU.bytes), PDU.length)
                CFSocketSendData(socket, nil, data, kDefaultTimeout)
                return
            }

            CFSocketInvalidate(socket)

            let destinationTime = currentTime()
            let retainedClosure = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(info))
            let completion = unsafeBitCast(retainedClosure.takeUnretainedValue(), ObjCCompletionType.self)

            let data = unsafeBitCast(data, CFDataRef.self) as NSData?
            completion(data, destinationTime)
            retainedClosure.release()
        }

        let types = CFSocketCallBackType.DataCallBack.rawValue | CFSocketCallBackType.WriteCallBack.rawValue
        var context = CFSocketContext(version: 0, info: completion, retain: nil, release: nil,
                                      copyDescription: nil)
        guard let socket = CFSocketCreate(nil, PF_INET, SOCK_DGRAM, IPPROTO_UDP, types, callback, &context)
            where CFSocketIsValid(socket) else
        {
            return nil
        }

        let runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes)

        CFSocketConnectToAddress(socket, self.addressDataFromIP(ip, port: port), timeout)
        return (runLoopSource, socket)
    }

    private func addressDataFromIP(ip: String, port: Int) -> CFData {
        var address = sockaddr_in()
        address.sin_len = UInt8(sizeofValue(address))
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        inet_aton(ip, &address.sin_addr)

        return withUnsafePointer(&address) { pointer -> CFData in
            return CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(pointer), sizeofValue(address))
        }
    }
}

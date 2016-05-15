import Foundation

private let kDefaultTimeout = 5.0
private let kDefaultSamples = 4

private typealias ObjCCompletionType = @convention(block) (NSData?, NSTimeInterval) -> Void

/**
 NTP client session.
 */
final class NTPClient {

    /**
     Query the all ips that resolve from the given pool.

     - parameter pool:       Server socket address
     - parameter port:       Server port
     - parameter version:    NTP version to use (default 3)
     - parameter numberOfSamples:individual timeout for each of the NTP operations
     - parameter timeout:    The individual timeout for each of the NTP operations
     - parameter completion: A closure that will be response PDU on success or nil on error.
     */
    func queryPool(pool: String = "pool.ntp.org", version: Int8 = 3, port: Int = 123,
                   numberOfSamples: Int = kDefaultSamples, timeout: CFTimeInterval = kDefaultTimeout,
                   progress: (offset: NSTimeInterval?) -> Void)
    {
        var servers: [String: [NTPPacket]] = [:]

        let queryIPAndStoreResult = { [weak self] (address: String) -> Void in
            self?.queryIP(address, port: port, version: version, timeout: timeout) { packet in
                defer {
                    let responses = Array(servers.values)
                    progress(offset: self?.offsetFromResponses(responses))
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
            for _ in 0 ..< numberOfSamples {
                addresses.forEach(queryIPAndStoreResult)
            }
        }
    }

    /**
     Query the given ntp server for the time exchange.

     - parameter ip:         Server socket address
     - parameter port:       Server port
     - parameter version:    NTP version to use (default 3)
     - parameter timeout:    Timeout on socket operations
     - parameter completion: A closure that will be response PDU on success or nil on error.
     */
    func queryIP(ip: String, port: Int = 123, version: Int8 = 3, timeout: CFTimeInterval = kDefaultTimeout,
                 completion: (PDU: NTPPacket?) -> Void)
    {
        var timer: NSTimer? = nil
        let bridgeCallback: ObjCCompletionType = { data, destinationTime in
            timer?.invalidate()
            guard let data = data, PDU = try? NTPPacket(data: data, destinationTime: destinationTime) else {
                return completion(PDU: nil)
            }

            completion(PDU: PDU.isValidResponse(forVersion: version) ? PDU : nil)
        }

        let callback = unsafeBitCast(bridgeCallback, AnyObject.self)
        let retainedCallback = Unmanaged.passRetained(callback)
        let sourceAndSocket = self.sendAsyncUDPQuery(
            to: ip, port: port, timeout: timeout,
            completion: UnsafeMutablePointer<Void>(retainedCallback.toOpaque())
        )

        timer = NSTimer.scheduledTimerWithTimeInterval(timeout) { _ in
            completion(PDU: nil)
            retainedCallback.release()

            if let (source, socket) = sourceAndSocket {
                CFSocketInvalidate(socket)
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, kCFRunLoopCommonModes)
            }
        }
    }

    // MARK: - Private helpers (NTP Calculation)

    private func offsetFromResponses(responses: [[NTPPacket]]) -> NSTimeInterval? {
        let bestResponses = responses
            .flatMap { serverResponses in
                serverResponses.minElement { $0.delay < $1.delay }
            }

        return bestResponses.count > 0 ? bestResponses[bestResponses.count / 2].offset : nil
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
                CFSocketSendData(socket, address, data, kDefaultTimeout)
                return
            }

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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            CFSocketSetSocketFlags(socket, kCFSocketCloseOnInvalidate)
            CFSocketConnectToAddress(socket, self.addressDataFromIP(ip, port: port), timeout)
        }

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

/**
 From RFC 2030 (with a correction to the delay math):
 
     Timestamp Name          ID   When Generated
     ------------------------------------------------------------
     Originate Timestamp     T1   time request sent by client
     Receive Timestamp       T2   time request received by server
     Transmit Timestamp      T3   time reply sent by server
     Destination Timestamp   T4   time reply received by client
 
  The roundtrip delay d and local clock offset t are defined as
 
    d = (T4 - T1) - (T3 - T2)     t = ((T2 - T1) + (T3 - T4)) / 2.
 */
extension NTPPacket {

    /// Clocks offset in seconds.
    var offset: NSTimeInterval {
        return ((self.receiveTime - self.originTime) + (self.transmitTime - self.destinationTime)) / 2.0
    }

    /// Round-trip delay in seconds
    var delay: NSTimeInterval {
        return (self.destinationTime - self.originTime) - (self.transmitTime - self.receiveTime)
    }
}

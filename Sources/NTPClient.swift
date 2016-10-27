import Foundation

private let kDefaultTimeout = 6.0
private let kDefaultSamples = 4
private let kMaximumNTPServers = 5
private let kMaximumResultDispersion = 10.0

private typealias ObjCCompletionType = @convention(block) (Data?, TimeInterval) -> Void

/// Exception raised while sending / receiving NTP packets.
enum NTPNetworkError: Error {
    case noValidNTPPacketFound
}

/// NTP client session.
final class NTPClient {

    /// Query the all ips that resolve from the given pool.
    ///
    /// - parameter pool:            NTP pool that will be resolved into multiple NTP servers.
    /// - parameter port:            Server NTP port (default 123).
    /// - parameter version:         NTP version to use (default 3).
    /// - parameter numberOfSamples: The number of samples to be acquired from each server (default 4).
    /// - parameter maximumServers:  The maximum number of servers to be queried (default 5).
    /// - parameter timeout:         The individual timeout for each of the NTP operations.
    /// - parameter completion:      A closure that will be response PDU on success or nil on error.
    func query(pool: String = "time.apple.com", version: Int8 = 3, port: Int = 123,
                   numberOfSamples: Int = kDefaultSamples, maximumServers: Int = kMaximumNTPServers,
                   timeout: CFTimeInterval = kDefaultTimeout,
                   progress: @escaping (TimeInterval?, Int, Int) -> Void)
    {
        var servers: [InternetAddress: [NTPPacket]] = [:]
        var completed: Int = 0

        let queryIPAndStoreResult = { (address: InternetAddress, totalQueries: Int) -> Void in
            self.query(ip: address, port: port, version: version, timeout: timeout,
                         numberOfSamples: numberOfSamples)
            { packet in
                defer {
                    completed += 1

                    let responses = Array(servers.values)
                    progress(try? self.offset(from: responses), completed, totalQueries)
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
                return progress(nil, 0, 0)
            }

            let totalServers = min(addresses.count, maximumServers)
            for address in addresses[0 ..< totalServers] {
                queryIPAndStoreResult(address, totalServers * numberOfSamples)
            }
        }
    }

    /// Query the given ntp server for the time exchange.
    ///
    /// - parameter ip:              Server socket address.
    /// - parameter port:            Server NTP port (default 123).
    /// - parameter version:         NTP version to use (default 3).
    /// - parameter timeout:         Timeout on socket operations.
    /// - parameter numberOfSamples: The number of samples to be acquired from the server (default 4).
    /// - parameter completion:      A closure that will be response PDU on success or nil on error.
    func query(ip: InternetAddress, port: Int = 123, version: Int8 = 3,
               timeout: CFTimeInterval = kDefaultTimeout, numberOfSamples: Int = kDefaultSamples,
               completion: @escaping (NTPPacket?) -> Void)
    {
        var timer: Timer? = nil
        let bridgeCallback: ObjCCompletionType = { data, destinationTime in
            defer {
                // If we still have samples left; we'll keep querying the same server
                if numberOfSamples > 1 {
                    self.query(ip: ip, port: port, version: version, timeout: timeout,
                               numberOfSamples: numberOfSamples - 1, completion: completion)
                }
            }

            timer?.invalidate()
            guard
                let data = data, let PDU = try? NTPPacket(data: data, destinationTime: destinationTime) else
            {
                return completion(nil)
            }

            completion(PDU.isValidResponse() ? PDU : nil)
        }

        let callback = unsafeBitCast(bridgeCallback, to: AnyObject.self)
        let retainedCallback = Unmanaged.passRetained(callback)
        let sourceAndSocket = self.sendAsyncUDPQuery(
            to: ip, port: port, timeout: timeout,
            completion: UnsafeMutableRawPointer(retainedCallback.toOpaque())
        )

        timer = BlockTimer.scheduledTimer(withTimeInterval: timeout, repeated: true) { _ in
            bridgeCallback(nil, TimeInterval.infinity)
            retainedCallback.release()

            if let (source, socket) = sourceAndSocket {
                CFSocketInvalidate(socket)
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, CFRunLoopMode.commonModes)
            }
        }
    }

    // MARK: - Private helpers (NTP Calculation)

    private func offset(from responses: [[NTPPacket]]) throws -> TimeInterval {
        let now = currentTime()
        var bestResponses: [NTPPacket] = []
        for serverResponses in responses {
            let filtered = serverResponses
                .filter { abs($0.originTime - now) < kMaximumResultDispersion }
                .min { $0.delay < $1.delay }

            if let filtered = filtered {
                bestResponses.append(filtered)
            }
        }

        if bestResponses.count == 0 {
            throw NTPNetworkError.noValidNTPPacketFound
        }

        bestResponses.sort { $0.offset < $1.offset }
        return bestResponses[bestResponses.count / 2].offset
    }

    // MARK: - Private helpers (CFSocket)

    private func sendAsyncUDPQuery(to ip: InternetAddress, port: Int, timeout: TimeInterval,
                                   completion: UnsafeMutableRawPointer) -> (CFRunLoopSource, CFSocket)?
    {
        let callback: CFSocketCallBack = { socket, callbackType, address, data, info in
            if callbackType == .writeCallBack {
                var packet = NTPPacket()
                let PDU = packet.prepareToSend() as CFData
                CFSocketSendData(socket, nil, PDU, kDefaultTimeout)
                return
            }

            guard let info = info else {
                return
            }

            CFSocketInvalidate(socket)

            let destinationTime = currentTime()
            let retainedClosure = Unmanaged<AnyObject>.fromOpaque(info)
            let completion = unsafeBitCast(retainedClosure.takeUnretainedValue(), to: ObjCCompletionType.self)

            let data = unsafeBitCast(data, to: CFData.self) as Data?
            completion(data, destinationTime)
            retainedClosure.release()
        }

        let types = CFSocketCallBackType.dataCallBack.rawValue | CFSocketCallBackType.writeCallBack.rawValue
        var context = CFSocketContext(version: 0, info: completion, retain: nil, release: nil,
                                      copyDescription: nil)
        guard let socket = CFSocketCreate(nil, ip.family, SOCK_DGRAM, IPPROTO_UDP, types, callback, &context),
            CFSocketIsValid(socket) else
        {
            return nil
        }

        let runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, CFRunLoopMode.commonModes)

        var noSIGPIPE: UInt32 = 1
        setsockopt(CFSocketGetNative(socket), SOL_SOCKET, SO_NOSIGPIPE, &noSIGPIPE, 4)
        CFSocketConnectToAddress(socket, ip.addressData(withPort: port), timeout)
        return (runLoopSource!, socket)
    }
}

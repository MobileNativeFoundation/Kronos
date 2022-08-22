import Foundation

/// This enum represents an internet address that can either be IPv4 or IPv6.
///
/// - IPv6: An Internet Address of type IPv6 (e.g.: '::1').
/// - IPv4: An Internet Address of type IPv4 (e.g.: '127.0.0.1').
enum InternetAddress: Hashable {
    case ipv6(sockaddr_in6)
    case ipv4(sockaddr_in)

    /// Human readable host represetnation (e.g. '192.168.1.1' or 'ab:ab:ab:ab:ab:ab:ab:ab').
    var host: String? {
        switch self {
        case .ipv6(var address):
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &address.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
            return String(cString: buffer)

        case .ipv4(var address):
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &address.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN))
            return String(cString: buffer)
        }
    }

    /// The protocol family that should be used on the socket creation for this address.
    var family: Int32 {
        switch self {
        case .ipv4:
            return PF_INET

        case .ipv6:
            return PF_INET6
        }
    }
    
    /// If the address is reserved for private internets (local / private IP).
    var isPrivate: Bool {
        guard let host = host else {
            return false
        }
        
        switch self {
        case .ipv6:
            // Ref.:  https://datatracker.ietf.org/doc/html/rfc4193#section-3
            // +--------+-+------------+-----------+----------------------------+
            // | 7 bits |1|  40 bits   |  16 bits  |          64 bits           |
            // +--------+-+------------+-----------+----------------------------+
            // | Prefix |L| Global ID  | Subnet ID |        Interface ID        |
            // +--------+-+------------+-----------+----------------------------+
            //
            // Local IP is expected to have FC00::/7 prefix (7 bits) and L byte set to 1,
            // which effectively means `fd` prefix for local IPs.
            let localPrefix = "fd"
            
            // Ref.: https://datatracker.ietf.org/doc/html/rfc4291#section-2.4
            let multicastPrefix = "ff"
            
            let hostLowercased = host.lowercased()
            return hostLowercased.starts(with: localPrefix)
            || hostLowercased.starts(with: multicastPrefix)
        case .ipv4:
            // Ref.: https://datatracker.ietf.org/doc/html/rfc1918#section-3
            // Local IPs have predefined ranges:
            // - class A: 10.0.0.0 — 10.255.255.255
            // - class B: 172.16.0.0 — 172.31.255.255
            // - class C: 192.168.0.0 — 192.168.255.255
            let classABCregex = #"^((10\.)|(172\.1[6-9]\.)|(172\.2[0-9]\.)|(172\.3[0-1]\.)|(192\.168\.))"#
            
            // Ref.: https://datatracker.ietf.org/doc/html/rfc5771#section-3
            // Multicast address (range 224.0.0.0 - 239.255.255.255) are considered to be local network
            // addresses too (https://developer.apple.com/forums/thread/663848)
            //
            let multicastRegex = #"^((22[4-9]\.)|(23[0-9]\.))"#
            let broadcastIP = "255.255.255.255"
            
            return host.range(of: classABCregex, options: .regularExpression) != nil
            || host.range(of: multicastRegex, options: .regularExpression) != nil
            || host == broadcastIP
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.host)
    }

    init?(dataWithSockAddress data: NSData) {
        let storage = sockaddr_storage.from(unsafeDataWithSockAddress: data)
        switch Int32(storage.ss_family) {
        case AF_INET:
            self = storage.withUnsafeAddress { InternetAddress.ipv4($0.pointee) }

        case AF_INET6:
            self = storage.withUnsafeAddress { InternetAddress.ipv6($0.pointee) }

        default:
            return nil
        }
    }

    /// Returns the address struct (either sockaddr_in or sockaddr_in6) represented as an CFData.
    ///
    /// - parameter port: The port number to associate on the address struct.
    ///
    /// - returns: An address struct wrapped into a CFData type.
    func addressData(withPort port: Int) -> CFData {
        switch self {
        case .ipv6(var address):
            address.sin6_port = in_port_t(port).bigEndian
            return Data(bytes: &address, count: MemoryLayout<sockaddr_in6>.size) as CFData

        case .ipv4(var address):
            address.sin_port = in_port_t(port).bigEndian
            return Data(bytes: &address, count: MemoryLayout<sockaddr_in>.size) as CFData
        }
    }
}

/// Compare InternetAddress(es) by making sure the host representation are equal.
func == (lhs: InternetAddress, rhs: InternetAddress) -> Bool {
    return lhs.host == rhs.host
}

// MARK: - sockaddr_storage helpers

extension sockaddr_storage {
    /// Creates a new storage value from a data type that contains the memory layout of a sockaddr_t. This
    /// is used to create sockaddr_storage(s) from some of the CF C functions such as `CFHostGetAddressing`.
    ///
    /// !!! WARNING: This method is unsafe and assumes the memory layout is of `sockaddr_t`. !!!
    ///
    /// - parameter data: The data to be interpreted as sockaddr
    /// - returns: The newly created sockaddr_storage value
    fileprivate static func from(unsafeDataWithSockAddress data: NSData) -> sockaddr_storage {
        var storage = sockaddr_storage()
        data.getBytes(&storage, length: data.length)
        return storage
    }

    /// Calls a closure with traditional BSD Sockets address parameters.
    ///
    /// - parameter body: A closure to call with `self` referenced appropriately for calling
    ///   BSD Sockets APIs that take an address.
    ///
    /// - throws: Any error thrown by `body`.
    ///
    /// - returns: Any result returned by `body`.
    fileprivate func withUnsafeAddress<T, U>(_ body: (_ address: UnsafePointer<U>) -> T) -> T {
        var storage = self
        return withUnsafePointer(to: &storage) {
            $0.withMemoryRebound(to: U.self, capacity: 1) { address in body(address) }
        }
    }
}

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

    var hashValue: Int {
        return self.host?.hashValue ?? 0
    }

    init?(storage: UnsafePointer<sockaddr_storage>) {

        switch Int32(storage.pointee.ss_family) {
            case AF_INET:
                self = storage.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { address in
                    InternetAddress.ipv4(address.pointee)
                }

            case AF_INET6:
                self = storage.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { address in
                    InternetAddress.ipv6(address.pointee)
                }
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

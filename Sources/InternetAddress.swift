import Foundation

/**
 This enum represents an internet address that can either be IPv4 or IPv6.

 - IPv6: An Internet Address of type IPv6 (e.g.: '::1')
 - IPv4: An Internet Address of type IPv4 (e.g.: '127.0.0.1')
 */
enum InternetAddress: Hashable {
    case IPv6(sockaddr_in6)
    case IPv4(sockaddr_in)

    /// Human readable host represetnation (e.g. '192.168.1.1' or 'ab:ab:ab:ab:ab:ab:ab:ab').
    var host: String? {
        switch self {
            case IPv6(var address):
                var buffer = [CChar](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)
                inet_ntop(AF_INET6, &address.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
                return String.fromCString(buffer)

            case IPv4(var address):
                var buffer = [CChar](count: Int(INET_ADDRSTRLEN), repeatedValue: 0)
                inet_ntop(AF_INET, &address.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                return String.fromCString(buffer)
        }
    }

    /// The protocol family that should be used on the socket creation for this address.
    var family: Int32 {
        switch self {
            case .IPv4:
                return PF_INET

            case .IPv6:
                return PF_INET6
        }
    }

    var hashValue: Int {
        return self.host?.hashValue ?? 0
    }

    init?(storage: UnsafePointer<sockaddr_storage>) {
        if storage == nil {
            return nil
        }

        switch Int32(storage.memory.ss_family) {
            case AF_INET:
                let address = UnsafeMutablePointer<sockaddr_in>(storage)
                self = IPv4(address.memory)

            case AF_INET6:
                let address = UnsafeMutablePointer<sockaddr_in6>(storage)
                self = IPv6(address.memory)

            default:
                return nil
        }
    }

    /**
     Returns the address struct (either sockaddr_in or sockaddr_in6) represented as an CFData.

     - parameter port: The port number to associate on the address struct.

     - returns: An address struct wrapped into a CFData type.
     */
    func addressData(withPort port: Int) -> CFData {
        switch self {
            case IPv6(var address):
                address.sin6_port = in_port_t(port).bigEndian
                return withUnsafePointer(&address) { pointer -> CFData in
                    CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(pointer), sizeofValue(address))
                }

            case IPv4(var address):
                address.sin_port = in_port_t(port).bigEndian
                return withUnsafePointer(&address) { pointer -> CFData in
                    CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(pointer), sizeofValue(address))
                }
        }
    }
}

/**
 Compare InternetAddress(es) by making sure the host representation are equal.
 */
func == (lhs: InternetAddress, rhs: InternetAddress) -> Bool {
    return lhs.host == rhs.host
}

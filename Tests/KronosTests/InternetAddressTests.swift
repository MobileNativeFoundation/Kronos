import XCTest
@testable import Kronos

/// Extension used to generate random UInt8 values within the given bounds and excluding the given value set.
extension UInt8 {
    static func mockRandom(min: Self = .min, max: Self = .max, otherThan values: Set<Self> = []) -> Self {
          var random: Self = .random(in: min...max)
          while values.contains(random) { random = .random(in: min...max) }
          return random
      }
}

class InternetAddressTests: XCTestCase {
    func testIfIPv4AddressIsPrivate() throws {
        let privateIPs: [InternetAddress] = try (0..<50).flatMap { _ in
            return [
                // random private IPs of class A: 10.0.0.0 — 10.255.255.255
                try .mockIPv4([10, .mockRandom(), .mockRandom(), .mockRandom()]),
                // random private IPs of class B: 172.16.0.0 — 172.31.255.255
                try .mockIPv4([172, .mockRandom(min: 16, max: 31), .mockRandom(), .mockRandom()]),
                // random private IPs of class C: 192.168.0.0 — 192.168.255.255
                try .mockIPv4([192, 168, .mockRandom(), .mockRandom()]),
                // multicast IPs 224.0.0.0 - 239.255.255.255
                try .mockIPv4([.mockRandom(min: 224, max: 239), .mockRandom(), .mockRandom(), .mockRandom()]),
                // broadcast IP 255.255.255.255
                try .mockIPv4([255, 255, 255, 255]),
            ]
        }
        let publicIPs: [InternetAddress] = try (0..<50).flatMap { _ in
            return [
                try .mockIPv4([.mockRandom(otherThan: Set<UInt8>([10, 172, 192, 255] + (224...239))), .mockRandom(), .mockRandom(), .mockRandom()]),
                try .mockIPv4([172, .mockRandom(min: 0, max: 15), .mockRandom(), .mockRandom()]),
                try .mockIPv4([172, .mockRandom(min: 32, max: 255), .mockRandom(), .mockRandom()]),
                try .mockIPv4([192, .mockRandom(otherThan: [168]), .mockRandom(), .mockRandom()]),
                try .mockIPv4([255, .mockRandom(max: 254), .mockRandom(), .mockRandom()]),
                try .mockIPv4([255, .mockRandom(), .mockRandom(max: 254), .mockRandom()]),
                try .mockIPv4([255, .mockRandom(), .mockRandom(), .mockRandom(max: 254)]),
            ]
        }
        
        privateIPs.forEach { ip in
            XCTAssertTrue(ip.isPrivate, "\(ip.host ?? "nil") should be private IP")
        }
        publicIPs.forEach { ip in
            XCTAssertFalse(ip.isPrivate, "\(ip.host ?? "nil") should not be private IP")
        }
    }
    
    func testIfIPv6AddressIsPrivate() throws {
        let privateIPs: [InternetAddress] = try (0..<50).flatMap { _ in
            return [
                // random private IP starting with `fd` prefix
                try .mockIPv6([0xfd] + (0..<15).map({ _ in .mockRandom() })),
                // random multicast IP starting with `ff` prefix
                try .mockIPv6([0xff] + (0..<15).map({ _ in .mockRandom() })),
            ]
        }
        let publicIPs: [InternetAddress] = try (0..<50).flatMap { _ in
            return [
                // first byte is mocked to avoid having `fd` or `ff` prefix
                try .mockIPv6([.mockRandom(min: 0xf0, otherThan: [0xfd, 0xff])] + (0..<15).map({ _ in .mockRandom() })),
                try .mockIPv6([.mockRandom(max: 0xfc, otherThan: [0xf])] + (0..<15).map({ _ in .mockRandom() })),
            ]
        }
        
        privateIPs.forEach { ip in
            XCTAssertTrue(ip.isPrivate, "\(ip.host ?? "nil") should be private IP")
        }
        publicIPs.forEach { ip in
            XCTAssertFalse(ip.isPrivate, "\(ip.host ?? "nil") should not be private IP")
        }
    }
}

// MARK: - Mocks

private extension InternetAddress {
    static func mockIPv4(_ bytes: [UInt8]) throws -> InternetAddress {
        precondition(bytes.count == 4, "Expected 4 bytes")
        let numbers = bytes.map { String($0) }
        let ipv4String = numbers.joined(separator: ".") // e.g. '192.168.1.1'
        let address: InternetAddress? = .mockWith(ipv4String: ipv4String)
        return try XCTUnwrap(address, "\(ipv4String) is not a valid IPv4 string")
    }
    
    static func mockIPv6(_ bytes: [UInt8]) throws -> InternetAddress {
        precondition(bytes.count == 16, "Expected 16 bytes")
        let groups: [String] = (0..<8).map { idx in
            let hexA = String(bytes[idx * 2], radix: 16)
            let hexB = String(bytes[idx * 2 + 1], radix: 16)
            return hexA + hexB
        }
        let ipv6String = groups.joined(separator: ":") // e.g. 'ab:ab:ab:ab:ab:ab:ab:ab'
        let randomcasedIpv6String = Bool.random() ? ipv6String.lowercased() : ipv6String.uppercased()
        let address: InternetAddress? = .mockWith(ipv6String: randomcasedIpv6String)
        return try XCTUnwrap(address, "\(ipv6String) is not a valid IPv6 string")
    }
    
    static func mockWith(ipv4String: String) -> InternetAddress? {
        var inaddr = in_addr()
        guard ipv4String.withCString({ inet_pton(AF_INET, $0, &inaddr) }) == 1 else {
            return nil // likely, not an IPv4 string
        }
        
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout.size(ofValue: addr))
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr = inaddr
        return .ipv4(addr)
    }
    
    static func mockWith(ipv6String: String) -> InternetAddress? {
        var inaddr = in6_addr()
        guard ipv6String.withCString({ inet_pton(AF_INET6, $0, &inaddr) }) == 1 else {
            return nil // likely, not an IPv6 string
        }
        
        var addr = sockaddr_in6()
        addr.sin6_len = UInt8(MemoryLayout.size(ofValue: addr))
        addr.sin6_family = sa_family_t(AF_INET6)
        addr.sin6_addr = inaddr
        return .ipv6(addr)
    }
}

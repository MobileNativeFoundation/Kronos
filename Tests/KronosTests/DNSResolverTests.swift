import XCTest
@testable import Kronos

final class DNSResolverTests: XCTestCase {

    func testResolveOneIP() {
        let expectation = self.expectation(description: "Query host's DNS for a single IP")
        DNSResolver.resolve(host: "lyft.com") { addresses in
            XCTAssertEqual(addresses.count, 1)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { _ in }
    }

    func testResolveMultipleIP() {
        let expectation = self.expectation(description: "Query host's DNS for multiple IPs")
        DNSResolver.resolve(host: "pool.ntp.org") { addresses in
            XCTAssertGreaterThan(addresses.count, 1)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { _ in }
    }

    func testResolveIPv6() {
        let expectation = self.expectation(description: "Query host's DNS that supports IPv6")
        DNSResolver.resolve(host: "ipv6friday.org") { addresses in
            XCTAssertGreaterThan(addresses.count, 0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { _ in }
    }

    func testInvalidIP() {
        let expectation = self.expectation(description: "Query invalid host's DNS")
        DNSResolver.resolve(host: "l33t.h4x") { addresses in
            XCTAssertEqual(addresses.count, 0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5) { _ in }
    }

    func testTimeout() {
        let expectation = self.expectation(description: "DNS times out")
        DNSResolver.resolve(host: "ip6.nl", timeout: 0) { addresses in
            XCTAssertEqual(addresses.count, 0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1.0) { _ in }
    }
}

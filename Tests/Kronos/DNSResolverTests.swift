import XCTest
@testable import Kronos

final class DNSResolverTests: XCTestCase {

    func testResolveOneIP() {
        let expectation = self.expectationWithDescription("Query host's DNS for a single IP")
        DNSResolver.resolve(host: "lyft.com") { addresses in
            XCTAssertEqual(addresses.count, 1)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(5) { _ in }
    }

    func testResolveMultipleIP() {
        let expectation = self.expectationWithDescription("Query host's DNS for multiple IPs")
        DNSResolver.resolve(host: "pool.ntp.org") { addresses in
            XCTAssertGreaterThan(addresses.count, 1)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(5) { _ in }
    }

    func testResolveIPv6() {
        let expectation = self.expectationWithDescription("Query host's DNS that supports IPv6")
        DNSResolver.resolve(host: "ipv6friday.org") { addresses in
            for address in addresses {
                if case .IPv6 = address {
                    return expectation.fulfill()
                }
            }

            XCTFail("No IPv6 address found")
        }

        self.waitForExpectationsWithTimeout(5) { _ in }
    }

    func testInvalidIP() {
        let expectation = self.expectationWithDescription("Query invalid host's DNS")
        DNSResolver.resolve(host: "l33t.h4x") { addresses in
            XCTAssertEqual(addresses.count, 0)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(5) { _ in }
    }
}

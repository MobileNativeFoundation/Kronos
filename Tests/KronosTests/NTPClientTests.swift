import XCTest
@testable import Kronos

final class NTPClientTests: XCTestCase {

    func testQueryIP() {
        let expectation = self.expectation(description: "NTPClient queries single IPs")

        DNSResolver.resolve(host: "time.apple.com") { addresses in
            XCTAssertGreaterThan(addresses.count, 0)

            NTPClient().query(ip: addresses.first!, version: 3, numberOfSamples: 1) { PDU in
                XCTAssertNotNil(PDU)

                XCTAssertGreaterThanOrEqual(PDU!.version, 3)
                XCTAssertTrue(PDU!.isValidResponse())

                expectation.fulfill()
            }
        }

        self.waitForExpectations(timeout: 10)
    }

    func testQueryPool() {
        var expectation: XCTestExpectation? =
            self.expectation(description: "Offset from ref clock to local clock are accurate")
        NTPClient().query(pool: "0.pool.ntp.org", numberOfSamples: 1, maximumServers: 1) { offset, _, _ in
            XCTAssertNotNil(offset)

            NTPClient().query(pool: "0.pool.ntp.org", numberOfSamples: 1, maximumServers: 1)
            { offset2, _, _ in
                XCTAssertNotNil(offset2)
                XCTAssertLessThan(abs(offset! - offset2!), 0.10)
                expectation?.fulfill()
                expectation = nil
            }
        }

        self.waitForExpectations(timeout: 10)
    }

    func testQueryPoolWithIPv6() {
        var expectation: XCTestExpectation? =
            self.expectation(description: "NTPClient queries a pool that supports IPv6")
        NTPClient().query(pool: "2.pool.ntp.org", numberOfSamples: 1) { offset, _, _ in
            XCTAssertNotNil(offset)
            expectation?.fulfill()
            expectation = nil
        }

        self.waitForExpectations(timeout: 10)
    }
}

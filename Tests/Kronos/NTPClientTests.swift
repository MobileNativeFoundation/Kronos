import XCTest
@testable import Kronos

final class NTPClientTests: XCTestCase {

    override func tearDown() {
        super.setUp()
        Clock.reset()
    }

    func testQueryIP() {
        let expectation = self.expectationWithDescription("NTPClient queries single IPs")

        DNSResolver.resolve(host: "time.apple.com") { addresses in
            XCTAssertGreaterThan(addresses.count, 0)

            NTPClient().queryIP(addresses.first!, version: 3) { PDU in
                XCTAssertNotNil(PDU)

                XCTAssertGreaterThanOrEqual(PDU!.version, 3)
                XCTAssertTrue(PDU!.isValidResponse())

                expectation.fulfill()
            }
        }

        self.waitForExpectationsWithTimeout(10) { _ in }
    }

    func testQueryPool() {
        let expectation = self.expectationWithDescription("Offset from ref clock to local clock are accurate")
        NTPClient().queryPool("0.pool.ntp.org", numberOfSamples: 1) { offset, _, _ in
            NTPClient().queryPool("0.pool.ntp.org", numberOfSamples: 1) { offset2, _, _ in

                print(offset, offset2)
                XCTAssertLessThan(abs(offset - offset2), 0.005)
                expectation.fulfill()
            }
        }

        self.waitForExpectationsWithTimeout(10) { _ in }
    }
}

import XCTest
@testable import Kronos

final class NTPClientTests: XCTestCase {

    override func tearDown() {
        super.setUp()
        Clock.reset()
    }

    func testQueryPool() {
        let expectation = self.expectationWithDescription("Offset from ref clock to local clock are accurate")
        NTPClient().queryPool("blue.1e400.net", numberOfSamples: 2) { offset in
            XCTAssertNotNil(offset)

            NTPClient().queryPool("blue.1e400.net", numberOfSamples: 2) { offset2 in
                XCTAssertNotNil(offset2)
                XCTAssertLessThan(abs(offset! - offset2!), 0.005)
                expectation.fulfill()
            }
        }

        self.waitForExpectationsWithTimeout(10) { _ in }
    }

    func testQueryIP() {
        let expectation = self.expectationWithDescription("NTPClient queries single IPs")
        NTPClient().queryIP("71.19.145.222", version: 3) { PDU in
            XCTAssertNotNil(PDU)

            XCTAssertEqual(PDU!.version, 3)
            XCTAssertTrue(PDU!.isValidResponse(forVersion: 3))

            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(10) { _ in }
    }
}

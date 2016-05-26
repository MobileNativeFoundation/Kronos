import XCTest
@testable import Kronos

final class ClockTests: XCTestCase {

    override func tearDown() {
        super.setUp()
        Clock.reset()
    }

    func testFirst() {
        let expectation = self.expectationWithDescription("Clock sync calls first closure")
        Clock.sync { date, _ in
            XCTAssertNotNil(date)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(2) { _ in }
    }

    func testLast() {
        let expectation = self.expectationWithDescription("Clock sync calls last closure")
        Clock.sync(completion: { date, offset in
            XCTAssertNotNil(date)
            XCTAssertNotNil(offset)
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(10) { _ in }
    }

    func testBoth() {
        let firstExpectation = self.expectationWithDescription("Clock sync calls first closure")
        let lastExpectation = self.expectationWithDescription("Clock sync calls last closure")
        Clock.sync(
            completion: { _ in firstExpectation.fulfill() },
            first: { _ in lastExpectation.fulfill() })

        self.waitForExpectationsWithTimeout(10) { _ in }
    }
}

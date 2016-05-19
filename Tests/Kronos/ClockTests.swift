import XCTest
@testable import Kronos

final class ClockTests: XCTestCase {

    override func tearDown() {
        super.setUp()
        Clock.reset()
    }

    func testFirst() {
        let expectation = self.expectationWithDescription("Clock sync calls first closure")
        Clock.sync(first: { date, offset in
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(2) { _ in }
    }

    func testLast() {
        let expectation = self.expectationWithDescription("Clock sync calls last closure")
        Clock.sync(last: { date, offset in
            expectation.fulfill()
        })

        self.waitForExpectationsWithTimeout(10) { _ in }
    }

    func testBoth() {
        let firstExpectation = self.expectationWithDescription("Clock sync calls first closure")
        let lastExpectation = self.expectationWithDescription("Clock sync calls last closure")
        Clock.sync(
            last: { _ in firstExpectation.fulfill() },
            first: { _ in lastExpectation.fulfill() })

        self.waitForExpectationsWithTimeout(10) { _ in }
    }
}

import XCTest
@testable import Kronos

final class ClockTests: XCTestCase {

    override func tearDown() {
        super.setUp()
        Clock.reset()
    }

    func testFirst() {
        let expectation = self.expectation(description: "Clock sync calls first closure")
        Clock.sync(first: { date, _ in
            XCTAssertNotNil(date)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 2) { _ in }
    }

    func testLast() {
        let expectation = self.expectation(description: "Clock sync calls last closure")
        Clock.sync(completion: { date, offset in
            XCTAssertNotNil(date)
            XCTAssertNotNil(offset)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 10) { _ in }
    }

    func testBoth() {
        let firstExpectation = self.expectation(description: "Clock sync calls first closure")
        let lastExpectation = self.expectation(description: "Clock sync calls last closure")
        Clock.sync(
            first: { _ in lastExpectation.fulfill() },
            completion: { _ in firstExpectation.fulfill() })

        self.waitForExpectations(timeout: 10) { _ in }
    }
}

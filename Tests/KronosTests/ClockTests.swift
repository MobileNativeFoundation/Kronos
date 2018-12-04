import XCTest
@testable import Kronos

final class ClockTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Clock.reset()
    }

    func testFirst() {
        let expectation = self.expectation(description: "Clock sync calls first closure")
        Clock.sync(first: { date, _ in
            XCTAssertNotNil(date)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 2)
    }

    func testLast() {
        let expectation = self.expectation(description: "Clock sync calls last closure")
        Clock.sync(completion: { date, offset in
            XCTAssertNotNil(date)
            XCTAssertNotNil(offset)
            expectation.fulfill()
        })

        self.waitForExpectations(timeout: 20)
    }

    func testBoth() {
        let firstExpectation = self.expectation(description: "Clock sync calls first closure")
        let lastExpectation = self.expectation(description: "Clock sync calls last closure")
        Clock.sync(
            first: { _, _ in firstExpectation.fulfill() },
            completion: { _, _ in lastExpectation.fulfill() })

        self.waitForExpectations(timeout: 20)
    }


    func testNTPSyncTime() {
        let expectation = self.expectation(description: "Sync time is recorded on every sync")
        var firstDate: Date?
        Clock.sync(
            first: { _, _ in
                firstDate = Clock.nowAnnotated?.syncedOn
            },
            completion: { _, _ in
                XCTAssertNotNil(firstDate)
                XCTAssertNotNil(Clock.nowAnnotated?.syncedOn)
                XCTAssertGreaterThan(Clock.nowAnnotated!.syncedOn.timeIntervalSince1970,
                                     firstDate!.timeIntervalSince1970)
                expectation.fulfill()
            })

        self.waitForExpectations(timeout: 20)
    }
}

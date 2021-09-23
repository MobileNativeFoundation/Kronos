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

    func testCustomQueue() {
        let expectation = self.expectation(description: "Clock sync calls closure")
        expectation.expectedFulfillmentCount = 2

        let queue = DispatchQueue(label: "com.Lyft.Kronos.Test")

        Clock.sync(
            queue: queue,
            first: { _, _ in
                XCTAssertFalse(Thread.isMainThread)
                expectation.fulfill()
            },
            completion: { _, _ in
                XCTAssertFalse(Thread.isMainThread)
                expectation.fulfill()
            })

        self.waitForExpectations(timeout: 20)
    }
}

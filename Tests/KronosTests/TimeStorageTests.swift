@testable import Kronos
import XCTest

class TimeStoragePolicyTests: XCTestCase {
    func testInitWithStringGivesAppGroupType() {
        let group = TimeStoragePolicy(appGroupID: "com.test.something.mygreatapp")
        if case TimeStoragePolicy.appGroup(_) = group {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    func testInitWithNIlGivesStandardType() {
        let group = TimeStoragePolicy(appGroupID: nil)
        if case TimeStoragePolicy.standard = group {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }
}

class TimeStorageTests: XCTestCase {
    func testStoringAndRetrievingTimeFreeze() {
        let storage = TimeStorage(storagePolicy: .standard)
        let sampleFreeze = TimeFreeze(offset: 5000.32423)
        storage.stableTime = sampleFreeze
        let fromDefaults = storage.stableTime
        XCTAssertNotNil(fromDefaults)
        XCTAssertEqual(sampleFreeze.toDictionary(), fromDefaults!.toDictionary())
    }
}

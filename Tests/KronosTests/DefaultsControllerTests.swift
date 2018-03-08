@testable import Kronos
import XCTest

class UserDefaultsStateTests: XCTestCase {
    func testDefaultsStateStandardEquatablity() {
        let standard1: UserDefaultsState = .standard
        let standard2: UserDefaultsState = .standard
        XCTAssertEqual(standard1, standard2)
    }

    func testDefaultsStateGroupEquatable() {
        let groupID = "com.test.something.mygreatapp"
        let group1: UserDefaultsState = .appGroup(groupID)
        let group2: UserDefaultsState = .appGroup(groupID)
        XCTAssertEqual(group1, group2)
    }

    func testDefaultsStateGroupEqualityFalse() {
        let group1: UserDefaultsState = .appGroup("com.test.something.mygreatapp")
        let group2: UserDefaultsState = .appGroup("this isn't even a bundle!")
        XCTAssertNotEqual(group1, group2)
    }
}

class DefaultsControllerTests: XCTestCase {
    func testStoringAndRetrievingTimeFreeze() {
        let sampleFreeze = TimeFreeze(offset: 5000.32423)
        DefaultsController.stableTime = sampleFreeze
        let fromDefaults = DefaultsController.stableTime
        XCTAssertNotNil(fromDefaults)
        XCTAssertEqual(sampleFreeze.toDictionary(), fromDefaults!.toDictionary())
    }

    func testStoringNilRemovesFromDefaults() {
        DefaultsController.stableTime = TimeFreeze(offset: 5000.32423)
        XCTAssertNotNil(DefaultsController.stableTime)
        DefaultsController.stableTime = nil
        XCTAssertNil(DefaultsController.stableTime)
    }
}

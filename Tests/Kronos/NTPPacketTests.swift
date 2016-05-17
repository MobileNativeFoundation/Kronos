import XCTest
@testable import Kronos

final class NTPPacketTests: XCTestCase {
    func testToData() {
        var packet = NTPPacket()
        let data = packet.prepareToSend(transmitTime: 1463303662.776552)
        XCTAssertEqual(data, NSData(hex: "1b0004fa0001000000010000000000000000000000000000" +
                                         "00000000000000000000000000000000dae2bc6ec6cc1c00")!)
    }

    func testParseInvalidData() {
        let network = NSData(hex: "0badface")!
        let PDU = try? NTPPacket(data: network, destinationTime: 0)
        XCTAssertNil(PDU)
    }

    func testParseData() {
        let network = NSData(hex: "1c0203e90000065700000a68ada2c09cdae2d084a5a76d5fdae2d3354a529000dae2d32b" +
                                  "b38bab46dae2d32bb38d9e00")!
        let PDU = try! NTPPacket(data: network, destinationTime: 0)
        XCTAssertEqual(PDU.version, 3)
        XCTAssertEqual(PDU.leap, LeapIndicator.NoWarning)
        XCTAssertEqual(PDU.mode, Mode.Server)
        XCTAssertEqual(PDU.stratum, Stratum.Secondary)
        XCTAssertEqual(PDU.poll, 3)
        XCTAssertEqual(PDU.precision, -23)
    }

    func testParseTimeData() {
        let network = NSData(hex: "1c0203e90000065700000a68ada2c09cdae2d084a5a76d5fdae2d3354a529000dae2d32b" +
                                  "b38bab46dae2d32bb38d9e00")!
        let PDU = try! NTPPacket(data: network, destinationTime: 0)
        XCTAssertEqual(PDU.rootDelay, 0.0247650146484375)
        XCTAssertEqual(PDU.rootDispersion, 0.0406494140625)
        XCTAssertEqual(PDU.clockSource.ID, 2913124508)
        XCTAssertEqual(PDU.referenceTime, 1463308804.6470859051)
        XCTAssertEqual(PDU.originTime, 1463309493.2903223038)
        XCTAssertEqual(PDU.receiveTime, 1463309483.7013499737)
    }
}

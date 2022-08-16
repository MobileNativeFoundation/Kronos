import XCTest
@testable import Kronos

final class NTPPacketTests: XCTestCase {
    func testToData() {
        var packet = NTPPacket()
        let data = packet.prepareToSend(transmitTime: 1463303662.776552)
        XCTAssertEqual(data, Data(hex: "1b0004fa0001000000010000000000000000000000000000" +
                                       "00000000000000000000000000000000dae2bc6ec6cc1c00")!)
    }

    func testParseInvalidData() {
        let network = Data(hex: "0badface")!
        let PDU = try? NTPPacket(data: network, destinationTime: 0)
        XCTAssertNil(PDU)
    }

    func testParseData() {
        let network = Data(hex: "1c0203e90000065700000a68ada2c09cdae2d084a5a76d5fdae2d3354a529000dae2d32b" +
                                "b38bab46dae2d32bb38d9e00")!
        let PDU = try? NTPPacket(data: network, destinationTime: 0)
        XCTAssertEqual(PDU?.version, 3)
        XCTAssertEqual(PDU?.leap, LeapIndicator.noWarning)
        XCTAssertEqual(PDU?.mode, Mode.server)
        XCTAssertEqual(PDU?.stratum, Stratum.secondary)
        XCTAssertEqual(PDU?.poll, 3)
        XCTAssertEqual(PDU?.precision, -23)
    }

    func testParseTimeData() {
        let network = Data(hex: "1c0203e90000065700000a68ada2c09cdae2d084a5a76d5fdae2d3354a529000dae2d32b" +
                                "b38bab46dae2d32bb38d9e00")!
        let PDU = try? NTPPacket(data: network, destinationTime: 0)
        XCTAssertEqual(PDU?.rootDelay, 0.0247650146484375)
        XCTAssertEqual(PDU?.rootDispersion, 0.0406494140625)
        XCTAssertEqual(PDU?.clockSource.ID, 2913124508)
        XCTAssertEqual(PDU?.referenceTime, 1463308804.6470859051)
        XCTAssertEqual(PDU?.originTime, 1463309493.2903223038)
        XCTAssertEqual(PDU?.receiveTime, 1463309483.7013499737)
    }

    func testParseYear2036() {
        let formatter = DateFormatter()
        let hexWithRollover = "1b0004fa000100000001000000000000000000000000000000000000000000000000000" +
                              "0000000000000000000000000"
        formatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let networkData = Data(hex: hexWithRollover)!
        var PDU = try? NTPPacket(data: networkData, destinationTime: 0)
        let referenceTime = PDU.map { Date(timeIntervalSince1970: $0.referenceTime) }
        XCTAssertEqual(formatter.string(for: referenceTime), "2036-02-07 06:28:16")

        // The rollover happens at 2^32 - epoch_delta = 2,085,978,496
        XCTAssertEqual(PDU?.prepareToSend(transmitTime: 2085978496), networkData)
    }
}

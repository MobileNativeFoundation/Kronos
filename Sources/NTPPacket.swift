import Foundation

/// Delta between system and NTP time
private let kEpochDelta = 2208988800.0

/// This is the maximum that we'll tolerate for the client's time vs self.delay
private let kMaximumDelayDifference = 0.1
private let kMaximumDispersion = 100.0

/// Returns the current time in decimal EPOCH timestamp format.
///
/// - returns: The current time in EPOCH timestamp format.
func currentTime() -> TimeInterval {
    var current = timeval()
    let systemTimeError = gettimeofday(&current, nil) != 0
    assert(!systemTimeError, "system clock error: system time unavailable")

    return Double(current.tv_sec) + Double(current.tv_usec) / 1_000_000
}

struct NTPPacket {

    /// The leap indicator warning of an impending leap second to be inserted or deleted in the last
    /// minute of the current month.
    let leap: LeapIndicator

    /// Version Number (VN): This is a three-bit integer indicating the NTP version number, currently 3.
    let version: Int8

    /// The current connection mode.
    let mode: Mode

    /// Mode representing the statrum level of the local clock.
    let stratum: Stratum

    /// Indicates the maximum interval between successive messages, in seconds to the nearest power of two.
    /// The values that normally appear in this field range from 6 to 10, inclusive.
    let poll: Int8

    /// The precision of the local clock, in seconds to the nearest power of two. The values that normally
    /// appear in this field range from -6 for mains-frequency clocks to -18 for microsecond clocks found
    /// in some workstations.
    let precision: Int8

    /// The total roundtrip delay to the primary reference source, in seconds with fraction point between
    /// bits 15 and 16. Note that this variable can take on both positive and negative values, depending on
    /// the relative time and frequency errors. The values that normally appear in this field range from
    /// negative values of a few milliseconds to positive values of several hundred milliseconds.
    let rootDelay: TimeInterval

    /// Total dispersion to the reference clock, in EPOCH.
    let rootDispersion: TimeInterval

    /// Server or reference clock. This value is generated based on a reference identifier maintained by IANA.
    let clockSource: ClockSource

    /// Time when the system clock was last set or corrected, in EPOCH timestamp format.
    let referenceTime: TimeInterval

    /// Time at the client when the request departed for the server, in EPOCH timestamp format.
    let originTime: TimeInterval

    /// Time at the server when the request arrived from the client, in EPOCH timestamp format.
    let receiveTime: TimeInterval

    /// Time at the server when the response left for the client, in EPOCH timestamp format.
    var transmitTime: TimeInterval = 0.0

    /// Time at the client when the response arrived, in EPOCH timestamp format.
    let destinationTime: TimeInterval

    /// NTP protocol package representation.
    ///
    /// - parameter transmitTime: Packet transmission timestamp.
    /// - parameter version:      NTP protocol version.
    /// - parameter mode:         Packet mode (client, server).
    init(version: Int8 = 3, mode: Mode = .client) {
        self.version = version
        self.leap = .noWarning
        self.mode = mode
        self.stratum = .unspecified
        self.poll = 4
        self.precision = -6
        self.rootDelay = 1
        self.rootDispersion = 1
        self.clockSource = .referenceIdentifier(id: 0)
        self.referenceTime = -kEpochDelta
        self.originTime = -kEpochDelta
        self.receiveTime = -kEpochDelta
        self.destinationTime = -1
    }

    /// Creates a NTP package based on a network PDU.
    ///
    /// - parameter data:            The PDU received from the NTP call.
    /// - parameter destinationTime: The time where the package arrived (client time) in EPOCH format.
    /// - throws:                    NTPParsingError in case of an invalid response.
    init(data: Data, destinationTime: TimeInterval) throws {
        if data.count < 48 {
            throw NTPParsingError.invalidNTPPDU("Invalid PDU length: \(data.count)")
        }

        self.leap = LeapIndicator(rawValue: (data.getByte(at: 0) >> 6) & 0b11) ?? .noWarning
        self.version = data.getByte(at: 0) >> 3 & 0b111
        self.mode = Mode(rawValue: data.getByte(at: 0) & 0b111) ?? .unknown
        self.stratum = Stratum(value: data.getByte(at: 1))
        self.poll = data.getByte(at: 2)
        self.precision = data.getByte(at: 3)
        self.rootDelay = NTPPacket.intervalFromNTPFormat(data.getUnsignedInteger(at: 4))
        self.rootDispersion = NTPPacket.intervalFromNTPFormat(data.getUnsignedInteger(at: 8))
        self.clockSource = ClockSource(stratum: self.stratum, sourceID: data.getUnsignedInteger(at: 12))
        self.referenceTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(at: 16))
        self.originTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(at: 24))
        self.receiveTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(at: 32))
        self.transmitTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(at: 40))
        self.destinationTime = destinationTime
    }

    /// Convert this NTPPacket to a buffer that can be sent over a socket.
    ///
    /// - returns: A bytes buffer representing this packet.
    mutating func prepareToSend(transmitTime: TimeInterval? = nil) -> Data {
        var data = Data()
        data.append(byte: self.leap.rawValue << 6 | self.version << 3 | self.mode.rawValue)
        data.append(byte: self.stratum.rawValue)
        data.append(byte: self.poll)
        data.append(byte: self.precision)
        data.append(unsignedInteger: self.intervalToNTPFormat(self.rootDelay))
        data.append(unsignedInteger: self.intervalToNTPFormat(self.rootDispersion))
        data.append(unsignedInteger: self.clockSource.ID)
        data.append(unsignedLong: self.dateToNTPFormat(self.referenceTime))
        data.append(unsignedLong: self.dateToNTPFormat(self.originTime))
        data.append(unsignedLong: self.dateToNTPFormat(self.receiveTime))

        self.transmitTime = transmitTime ?? currentTime()
        data.append(unsignedLong: self.dateToNTPFormat(self.transmitTime))
        return data
    }

    /// Checks properties to make sure that the received PDU is a valid response that we can use.
    ///
    /// - returns: A boolean indicating if the response is valid for the given version.
    func isValidResponse() -> Bool {
        return (self.mode == .server || self.mode == .symmetricPassive) && self.leap != .alarm
            && self.stratum != .invalid && self.stratum != .unspecified
            && self.rootDispersion < kMaximumDispersion
            && abs(currentTime() - self.originTime - self.delay) < kMaximumDelayDifference
    }

    // MARK: - Private helpers

    private func dateToNTPFormat(_ time: TimeInterval) -> UInt64 {
        let integer = UInt32(time + kEpochDelta)
        let decimal = modf(time).1 * 4294967296.0 // 2 ^ 32
        return UInt64(integer) << 32 | UInt64(decimal)
    }

    private func intervalToNTPFormat(_ time: TimeInterval) -> UInt32 {
        let integer = UInt16(time)
        let decimal = modf(time).1 * 65536 // 2 ^ 16
        return UInt32(integer) << 16 | UInt32(decimal)
    }

    private static func dateFromNTPFormat(_ time: UInt64) -> TimeInterval {
        let integer = Double(time >> 32)
        let decimal = Double(time & 0xffffffff) / 4294967296.0
        return integer - kEpochDelta + decimal
    }

    private static func intervalFromNTPFormat(_ time: UInt32) -> TimeInterval {
        let integer = Double(time >> 16)
        let decimal = Double(time & 0xffff) / 65536
        return integer + decimal
    }
}

/// From RFC 2030 (with a correction to the delay math):
///
/// Timestamp Name          ID   When Generated
/// ------------------------------------------------------------
/// Originate Timestamp     T1   time request sent by client
/// Receive Timestamp       T2   time request received by server
/// Transmit Timestamp      T3   time reply sent by server
/// Destination Timestamp   T4   time reply received by client
///
/// The roundtrip delay d and local clock offset t are defined as
///
/// d = (T4 - T1) - (T3 - T2)     t = ((T2 - T1) + (T3 - T4)) / 2.
extension NTPPacket {

    /// Clocks offset in seconds.
    var offset: TimeInterval {
        return ((self.receiveTime - self.originTime) + (self.transmitTime - self.destinationTime)) / 2.0
    }

    /// Round-trip delay in seconds
    var delay: TimeInterval {
        return (self.destinationTime - self.originTime) - (self.transmitTime - self.receiveTime)
    }
}

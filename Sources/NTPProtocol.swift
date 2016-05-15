import Foundation

/// Delta between system and NTP time
private let kEpochDelta = 2208988800.0

/**
 Exception raised when the received PDU is invalid.
 */
enum NTPParsingError: ErrorType {
    case InvalidNTPPDU(String)
}

/**
 The leap indicator warning of an impending leap second to be inserted or deleted in the last
 minute of the current month.
 */
enum LeapIndicator: Int8 {
    case NoWarning, SixtyOneSeconds, FiftyNineSeconds, Alarm

    /// Human readable value of the leap warning.
    var description: String {
        switch self {
            case NoWarning:
               return "No warning"
            case SixtyOneSeconds:
               return "Last minute of the day has 61 seconds"
            case FiftyNineSeconds:
               return "Last minute of the day has 59 seconds"
            case Alarm:
               return "Unknown (clock unsynchronized)"
        }
    }
}

/**
 The connection mode.
 */
enum Mode: Int8 {
    case Reserved, SymmetricActive, SymmetricPassive, Client, Server, Broadcast, ReservedNTP, Unknown
}

/**
 Mode representing the statrum level of the clock.
 */
enum Stratum: Int8 {
    case Unspecified, Primary, Secondary, Invalid

    init(value: Int8) {
        switch value {
            case 0:
                self = Unspecified

            case 1:
                self = Primary

            case 0 ..< 15:
                self = Secondary

            default:
                self = Invalid
        }
    }
}

/**
 Server or reference clock. This value is generated based on the server stratum.
 
 - ReferenceClock:          Contains the sourceID and the description for the reference clock (stratum 1).
 - Debug(id):               Contains the kiss code for debug purposes (stratum 0).
 - ReferenceIdentifier(id): The reference identifier of the server (stratum > 1).
 */
enum ClockSource {
    case ReferenceClock(id: UInt32, description: String)
    case Debug(id: UInt32)
    case ReferenceIdentifier(id: UInt32)

    init(stratum: Stratum, sourceID: UInt32) {
        switch stratum {
            case .Unspecified:
                self = Debug(id: sourceID)

            case .Primary:
                let (id, description) = ClockSource.description(fromID: sourceID)
                self = ReferenceClock(id: id, description: description)

            case .Secondary, .Invalid:
                self = ReferenceIdentifier(id: sourceID)
        }
    }

    /// The id for the reference clock (IANA, stratum 1), debug (stratum 0) or referenceIdentifier
    var ID: UInt32 {
        switch self {
            case ReferenceClock(let id, _):
                return id

            case Debug(let id):
                return id

            case ReferenceIdentifier(let id):
                return id
        }
    }

    private static func description(fromID sourceID: UInt32) -> (UInt32, String) {
        switch sourceID {
            case 0x47505300:
                return (0x47505300, "Global Position System")
            case 0x47414c00:
                return (0x47414c00, "Galileo Positioning System")
            case 0x50505300:
                return (0x50505300, "Generic pulse-per-second")
            case 0x49524947:
                return (0x49524947, "Inter-Range Instrumentation Group")
            case 0x57575642:
                return (0x57575642, "LF Radio WWVB Ft. Collins, CO 60 kHz")
            case 0x44434600:
                return (0x44434600, "LF Radio DCF77 Mainflingen, DE 77.5 kHz")
            case 0x48424700:
                return (0x48424700, "LF Radio HBG Prangins, HB 75 kHz")
            case 0x4d534600:
                return (0x4d534600, "LF Radio MSF Anthorn, UK 60 kHz")
            case 0x4a4a5900:
                return (0x4a4a5900, "LF Radio JJY Fukushima, JP 40 kHz, Saga, JP 60 kHz")
            case 0x4c4f5243:
                return (0x4c4f5243, "MF Radio LORAN C station, 100 kHz")
            case 0x54444600:
                return (0x54444600, "MF Radio Allouis, FR 162 kHz")
            case 0x43485500:
                return (0x43485500, "HF Radio CHU Ottawa, Ontario")
            case 0x57575600:
                return (0x57575600, "HF Radio WWV Ft. Collins, CO")
            case 0x57575648:
                return (0x57575648, "HF Radio WWVH Kauai, HI")
            case 0x4e495354:
                return (0x4e495354, "NIST telephone modem")
            case 0x41435453:
                return (0x41435453, "ACTS telephone modem")
            case 0x55534e4f:
                return (0x55534e4f, "USNO telephone modem")
            case 0x50544200:
                return (0x50544200, "European telephone modem")
            case 0x4c4f434c:
                return (0x4c4f434c, "Uncalibrated local clock")
            case 0x4345534d:
                return (0x4345534d, "Calibrated Cesium clock")
            case 0x5242444d:
                return (0x5242444d, "Calibrated Rubidium clock")
            case 0x4f4d4547:
                return (0x4f4d4547, "OMEGA radio navigation system")
            case 0x44434e00:
                return (0x44434e00, "DCN routing protocol")
            case 0x54535000:
                return (0x54535000, "TSP time protocol")
            case 0x44545300:
                return (0x44545300, "Digital Time Service")
            case 0x41544f4d:
                return (0x41544f4d, "Atomic clock (calibrated)")
            case 0x564c4600:
                return (0x564c4600, "VLF radio (OMEGA,, etc.)")
            case 0x31505053:
                return (0x31505053, "External 1 PPS input")
            case 0x46524545:
                return (0x46524545, "(Internal clock)")
            case 0x494e4954:
                return (0x494e4954, "(Initialization)")
            default:
                return (0x0, "NULL")
        }
    }
}

/**
 Returns the current time in decimal EPOCH timestamp format.

 - returns: the current time in EPOCH timestamp format.
 */
func currentTime() -> NSTimeInterval {
    var current = timeval()
    if gettimeofday(&current, nil) != 0 {
        return 0
    }

    // Warning: we are not accounting here for leap seconds
    return Double(current.tv_sec) + 1.0e-6 * Double(current.tv_usec)
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
    let rootDelay: NSTimeInterval

    /// Total dispersion to the reference clock, in EPOCH.
    let rootDispersion: NSTimeInterval

    /// Server or reference clock. This value is generated based on a reference identifier maintained by IANA.
    let clockSource: ClockSource

    /// Time when the system clock was last set or corrected, in EPOCH timestamp format.
    let referenceTime: NSTimeInterval

    /// Time at the client when the request departed for the server, in EPOCH timestamp format.
    let originTime: NSTimeInterval

    /// Time at the server when the request arrived from the client, in EPOCH timestamp format.
    let receiveTime: NSTimeInterval

    /// Time at the server when the response left for the client, in EPOCH timestamp format.
    var transmitTime: NSTimeInterval = 0.0

    /// Time at the client when the response arrived, in EPOCH timestamp format.
    let destinationTime: NSTimeInterval

    /**
     NTP protocol package representation.

     - parameter transmitTime: Packet transmission timestamp
     - parameter version:      NTP protocol version.
     - parameter mode:         Packet mode (client, server)
    */
    init(version: Int8 = 3, mode: Mode = .Client) {
        self.version = version
        self.leap = .NoWarning
        self.mode = mode
        self.stratum = .Unspecified
        self.poll = 4
        self.precision = -6
        self.rootDelay = 1
        self.rootDispersion = 1
        self.clockSource = .ReferenceIdentifier(id: 0)
        self.referenceTime = -kEpochDelta
        self.originTime = -kEpochDelta
        self.receiveTime = -kEpochDelta
        self.destinationTime = -1
    }

    /**
     Creates a NTP package based on a network PDU.

     - parameter data:            The PDU received from the NTP call.
     - parameter destinationTime: The time where the package arrived (client time) in EPOCH format.
     */
    init(data: NSData, destinationTime: NSTimeInterval) throws {
        if data.length < 48 {
            throw NTPParsingError.InvalidNTPPDU("Invalid PDU length: \(data.length)")
        }

        self.leap = LeapIndicator(rawValue: (data.getByte(atIndex: 0) >> 6) & 0b11) ?? .NoWarning
        self.version = data.getByte(atIndex: 0) >> 3 & 0b111
        self.mode = Mode(rawValue: data.getByte(atIndex: 0) & 0b111) ?? .Unknown
        self.stratum = Stratum(value: data.getByte(atIndex: 1))
        self.poll = data.getByte(atIndex: 2)
        self.precision = data.getByte(atIndex: 3)
        self.rootDelay = NTPPacket.intervalFromNTPFormat(data.getUnsignedInteger(atIndex: 4))
        self.rootDispersion = NTPPacket.intervalFromNTPFormat(data.getUnsignedInteger(atIndex: 8))
        self.clockSource = ClockSource(stratum: self.stratum, sourceID: data.getUnsignedInteger(atIndex: 12))
        self.referenceTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(atIndex: 16))
        self.originTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(atIndex: 24))
        self.receiveTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(atIndex: 32))
        self.transmitTime = NTPPacket.dateFromNTPFormat(data.getUnsignedLong(atIndex: 40))
        self.destinationTime = destinationTime
    }

    /**
     Convert this NTPPacket to a buffer that can be sent over a socket.

     - returns: a bytes buffer representing this packet
     - throws: NTPException in case of invalid field
    */
    mutating func prepareToSend(transmitTime transmitTime: NSTimeInterval? = nil) -> NSData {
        let data = NSMutableData()
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

    /**
     Checks properties to make sure that the received PDU is a valid response that we can use.

     - parameter version: The request NTP version that should match with the received PDU.

     - returns: a boolean indicating if the response is valid for the given version.
     */
    func isValidResponse(forVersion version: Int8) -> Bool {
        return self.version == version && (self.mode == .Server || self.mode == .SymmetricPassive)
            && self.leap != .Alarm && self.stratum != .Invalid && self.stratum != .Unspecified
            && self.delay > 0
    }


    // MARK: - Private helpers

    private func dateToNTPFormat(time: NSTimeInterval) -> UInt64 {
        let integer = UInt32(time + kEpochDelta)
        let decimal = modf(time).1 * 4294967296.0 // 2 ^ 32
        return UInt64(integer) << 32 | UInt64(decimal)
    }

    private func intervalToNTPFormat(time: NSTimeInterval) -> UInt32 {
        let integer = UInt16(time)
        let decimal = modf(time).1 * 65536 // 2 ^ 16
        return UInt32(integer) << 16 | UInt32(decimal)
    }

    private static func dateFromNTPFormat(time: UInt64) -> NSTimeInterval {
        let integer = Double(time >> 32)
        let decimal = Double(time & 0xffffffff) / 4294967296.0
        return integer - kEpochDelta + decimal
    }

    private static func intervalFromNTPFormat(time: UInt32) -> NSTimeInterval {
        let integer = Double(time >> 16)
        let decimal = Double(time & 0xffff) / 65536
        return integer + decimal
    }
}

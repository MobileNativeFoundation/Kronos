import Foundation

/// Exception raised when the received PDU is invalid.
enum NTPParsingError: Error {
    case invalidNTPPDU(String)
}

/// The leap indicator warning of an impending leap second to be inserted or deleted in the last minute of the
/// current month.
enum LeapIndicator: Int8 {
    case noWarning, sixtyOneSeconds, fiftyNineSeconds, alarm

    /// Human readable value of the leap warning.
    var description: String {
        switch self {
            case .noWarning:
               return "No warning"
            case .sixtyOneSeconds:
               return "Last minute of the day has 61 seconds"
            case .fiftyNineSeconds:
               return "Last minute of the day has 59 seconds"
            case .alarm:
               return "Unknown (clock unsynchronized)"
        }
    }
}

/// The connection mode.
enum Mode: Int8 {
    case reserved, symmetricActive, symmetricPassive, client, server, broadcast, reservedNTP, unknown
}

/// Mode representing the statrum level of the clock.
enum Stratum: Int8 {
    case unspecified, primary, secondary, invalid

    init(value: Int8) {
        switch value {
            case 0:
                self = .unspecified

            case 1:
                self = .primary

            case 0 ..< 15:
                self = .secondary

            default:
                self = .invalid
        }
    }
}

/// Server or reference clock. This value is generated based on the server stratum.
///
/// - ReferenceClock:          Contains the sourceID and the description for the reference clock (stratum 1).
/// - Debug(id):               Contains the kiss code for debug purposes (stratum 0).
/// - ReferenceIdentifier(id): The reference identifier of the server (stratum > 1).
enum ClockSource {
    case referenceClock(id: UInt32, description: String)
    case debug(id: UInt32)
    case referenceIdentifier(id: UInt32)

    init(stratum: Stratum, sourceID: UInt32) {
        switch stratum {
            case .unspecified:
                self = .debug(id: sourceID)

            case .primary:
                let (id, description) = ClockSource.description(fromID: sourceID)
                self = .referenceClock(id: id, description: description)

            case .secondary, .invalid:
                self = .referenceIdentifier(id: sourceID)
        }
    }

    /// The id for the reference clock (IANA, stratum 1), debug (stratum 0) or referenceIdentifier
    var ID: UInt32 {
        switch self {
            case .referenceClock(let id, _):
                return id

            case .debug(let id):
                return id

            case .referenceIdentifier(let id):
                return id
        }
    }

    private static func description(fromID sourceID: UInt32) -> (UInt32, String) {
        let sourceMap: [UInt32: String] = [
            0x47505300: "Global Position System",
            0x47414c00: "Galileo Positioning System",
            0x50505300: "Generic pulse-per-second",
            0x49524947: "Inter-Range Instrumentation Group",
            0x57575642: "LF Radio WWVB Ft. Collins, CO 60 kHz",
            0x44434600: "LF Radio DCF77 Mainflingen, DE 77.5 kHz",
            0x48424700: "LF Radio HBG Prangins, HB 75 kHz",
            0x4d534600: "LF Radio MSF Anthorn, UK 60 kHz",
            0x4a4a5900: "LF Radio JJY Fukushima, JP 40 kHz, Saga, JP 60 kHz",
            0x4c4f5243: "MF Radio LORAN C station, 100 kHz",
            0x54444600: "MF Radio Allouis, FR 162 kHz",
            0x43485500: "HF Radio CHU Ottawa, Ontario",
            0x57575600: "HF Radio WWV Ft. Collins, CO",
            0x57575648: "HF Radio WWVH Kauai, HI",
            0x4e495354: "NIST telephone modem",
            0x41435453: "ACTS telephone modem",
            0x55534e4f: "USNO telephone modem",
            0x50544200: "European telephone modem",
            0x4c4f434c: "Uncalibrated local clock",
            0x4345534d: "Calibrated Cesium clock",
            0x5242444d: "Calibrated Rubidium clock",
            0x4f4d4547: "OMEGA radio navigation system",
            0x44434e00: "DCN routing protocol",
            0x54535000: "TSP time protocol",
            0x44545300: "Digital Time Service",
            0x41544f4d: "Atomic clock (calibrated)",
            0x564c4600: "VLF radio (OMEGA,, etc.)",
            0x31505053: "External 1 PPS input",
            0x46524545: "(Internal clock)",
            0x494e4954: "(Initialization)",
        ]

        return (sourceID, sourceMap[sourceID] ?? "NULL")
    }
}

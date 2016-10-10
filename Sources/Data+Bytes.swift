import Foundation

extension Data {

    /// Creates an Data instace based on a hex string (example: "ffff" would be <FF FF>).
    ///
    /// - parameter hex: The hex string without any spaces; should only have [0-9A-Fa-f].
    init?(hex: String) {
        if hex.characters.count % 2 != 0 {
            return nil
        }

        let hexArray = Array(hex.characters)
        var bytes: [UInt8] = []

        for index in stride(from: 0, to: hexArray.count, by: 2) {
            guard let byte = UInt8("\(hexArray[index])\(hexArray[index + 1])", radix: 16) else {
                return nil
            }

            bytes.append(byte)
        }

        self.init(bytes: bytes, count: bytes.count)
    }

    /// Gets one byte from the given index.
    ///
    /// - parameter index: The index of the byte to be retrieved. Note that this should never be >= length.
    ///
    /// - returns: The byte located at position `index`.
    func getByte(at index: Int) -> Int8 {
        let data: Int8 = self.subdata(in: index ..< (index + 1)).withUnsafeBytes { $0.pointee }
        return data
    }

    /// Gets an unsigned int (32 bits => 4 bytes) from the given index.
    ///
    /// - parameter index: The index of the uint to be retrieved. Note that this should never be >= length -
    ///                    3.
    ///
    /// - returns: The unsigned int located at position `index`.
    func getUnsignedInteger(at index: Int, bigEndian: Bool = true) -> UInt32 {
        let data: UInt32 =  self.subdata(in: index ..< (index + 4)).withUnsafeBytes { $0.pointee }
        return bigEndian ? data.bigEndian : data.littleEndian
    }

    /// Gets an unsigned long integer (64 bits => 8 bytes) from the given index.
    ///
    /// - parameter index: The index of the ulong to be retrieved. Note that this should never be >= length -
    ///                    7.
    ///
    /// - returns: The unsigned long integer located at position `index`.
    func getUnsignedLong(at index: Int, bigEndian: Bool = true) -> UInt64 {
        let data: UInt64 = self.subdata(in: index ..< (index + 8)).withUnsafeBytes { $0.pointee }
        return bigEndian ? data.bigEndian : data.littleEndian
    }


    /// Appends the given byte (8 bits) into the receiver Data.
    ///
    /// - parameter data: The byte to be appended.
    mutating func append(byte data: Int8) {
        var data = data
        self.append(UnsafeBufferPointer(start: &data, count: 1))
    }

    /// Appends the given unsigned integer (32 bits; 4 bytes) into the receiver Data.
    ///
    /// - parameter data: The unsigned integer to be appended.
    mutating func append(unsignedInteger data: UInt32, bigEndian: Bool = true) {
        var data = bigEndian ? data.bigEndian : data.littleEndian
        self.append(UnsafeBufferPointer(start: &data, count: 1))
    }

    /// Appends the given unsigned long (64 bits; 8 bytes) into the receiver Data.
    ///
    /// - parameter data: The unsigned long to be appended.
    mutating func append(unsignedLong data: UInt64, bigEndian: Bool = true) {
        var data = bigEndian ? data.bigEndian : data.littleEndian
        self.append(UnsafeBufferPointer(start: &data, count: 1))
    }
}

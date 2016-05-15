import Foundation

extension NSData {

    /**
     Creates an NSData instace based on a hex string (example: "ffff" would be <FF FF>).

     - parameter hex: The hex string without any spaces; should only have [0-9A-Fa-f]
     */
    convenience init?(hex: String) {
        if hex.characters.count % 2 != 0 {
            return nil
        }

        let hexArray = Array(hex.characters)
        var bytes: [UInt8] = []

        for index in 0.stride(to: hexArray.count, by: 2) {
            guard let byte = UInt8("\(hexArray[index])\(hexArray[index + 1])", radix: 16) else {
                return nil
            }

            bytes.append(byte)
        }

        self.init(bytes: bytes, length: bytes.count)
    }

    /**
     Gets one byte from the given index.

     - parameter index: The index of the byte to be retrieved. Note that this should never be >= length.

     - returns: the byte located at position `index`.
     */
    func getByte(atIndex index: Int) -> Int8 {
        var data: Int8 = 0
        self.getBytes(&data, range: NSRange(location: index, length: 1))
        return data
    }

    /**
     Gets an unsigned int (32 bits => 4 bytes) from the given index.

     - parameter index: The index of the uint to be retrieved. Note that this should never be >= length - 3.

     - returns: the unsigned int located at position `index`.
     */
    func getUnsignedInteger(atIndex index: Int, bigEndian: Bool = true) -> UInt32 {
        var data: UInt32 = 0
        self.getBytes(&data, range: NSRange(location: index, length: 4))
        return bigEndian ? data.bigEndian : data.littleEndian
    }

    /**
     Gets an unsigned long integer (64 bits => 8 bytes) from the given index.

     - parameter index: The index of the ulong to be retrieved. Note that this should never be >= length - 7.

     - returns: the unsigned long integer located at position `index`.
     */
    func getUnsignedLong(atIndex index: Int, bigEndian: Bool = true) -> UInt64 {
        var data: UInt64 = 0
        self.getBytes(&data, range: NSRange(location: index, length: 8))
        return bigEndian ? data.bigEndian : data.littleEndian
    }
}

extension NSMutableData {

    /**
     Appends the given byte (8 bits) into the receiver NSData.

     - parameter data: The byte to be appended.
     */
    func append(byte data: Int8) {
        var data = data
        self.appendBytes(&data, length: 1)
    }

    /**
     Appends the given unsigned integer (32 bits; 4 bytes) into the receiver NSData.

     - parameter data: The unsigned integer to be appended.
     */
    func append(unsignedInteger data: UInt32, bigEndian: Bool = true) {
        var data = bigEndian ? data.bigEndian : data.littleEndian
        self.appendBytes(&data, length: 4)
    }

    /**
     Appends the given unsigned long (64 bits; 8 bytes) into the receiver NSData.

     - parameter data: The unsigned long to be appended.
     */
    func append(unsignedLong data: UInt64, bigEndian: Bool = true) {
        var data = bigEndian ? data.bigEndian : data.littleEndian
        self.appendBytes(&data, length: 8)
    }
}

import Foundation

let client = NTPClient()
client.queryPool { offset in
    print(offset)
}

//var packet = NTPPacket()
//let data = packet.toData(transmitTime: 1463303662.776552)
//assert(data == NSData(hex: "1b000000000000000000000000000000000000000000000000000000000000000000000000000000dae2bc6ec6cc1c00")!)
//print(data) // 
//
//let network = NSData(hex: "1c0203e90000065700000a68ada2c09cdae2d084a5a76d5fdae2d3354a529000dae2d32bb38bab46dae2d32bb38d9e00")!
//let packet2 = try! NTPPacket(data: network)
//
//assert(packet2.version == 3)
//assert(packet2.leap == .NoWarning)
//assert(packet2.mode == .Server)
//assert(packet2.stratum == .Secondary)
//assert(packet2.poll == 3)
//assert(packet2.precision == -23)
//
//assert(packet2.rootDelay == 0.0247650146484375)
//assert(packet2.rootDispersion == 0.0406494140625)
//assert(packet2.clockSource.ID == 2913124508)
//
//assert(packet2.referenceTime == 1463308804.6470859051)
//assert(packet2.originTime == 1463309493.2903223038)
//assert(packet2.receiveTime == 1463309483.7013499737)
//

let runLoop = NSRunLoop.currentRunLoop()
while runLoop.runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture()) {}

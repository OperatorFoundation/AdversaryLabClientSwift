//
//  Parser.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/9/20.
//

import Foundation
import Datable

typealias UInt2 = UInt8
typealias UInt3 = UInt8
typealias UInt4 = UInt8
typealias UInt5 = UInt8
typealias UInt6 = UInt8
typealias UInt7 = UInt8

typealias UInt9 = UInt16
typealias UInt10 = UInt16
typealias UInt11 = UInt16
typealias UInt12 = UInt16
typealias UInt13 = UInt16

// IEEE 802.3 Ethernet frame
struct Ethernet
{
    let preamble: Data // 7 bytes
    let startDelimiter: UInt8 // 1 byte
    let MACDestination: Data // 6 bytes
    let MACSource: Data // 6 bytes
    let tag: Data? // 4 bytes
    let length: UInt16
    let payload: Data // variable, 46-1500 bytes, specified by length
    let crc: UInt32
}

struct IPv4
{
    let version: UInt4
    let IHL: UInt4
    let DSCP: UInt6
    let ECN: UInt2
    let length: UInt16
    let identification: UInt16
    let flags: UInt3
    let fragmentOffset: UInt13
    let ttl: UInt8
    let protocolNumber: UInt8
    let checksum: UInt16
    let sourceAddress: UInt32
    let destinationAddress: UInt32
    let options: UInt64?
    let payload: Data?
}

struct TCP
{
    let sourcePort: UInt16
    let destinationPort: UInt16
    let sequenceNumber: UInt32
    let acknowledgementNumber: UInt32?
    let offset: UInt4
    let ns: Bool
    let cwr: Bool
    let ece: Bool
    let urg: Bool
    let ack: Bool
    let psh: Bool
    let rst: Bool
    let syn: Bool
    let fin: Bool
    let windowSize: UInt16
    let checksum: UInt16
    let urgentPointeR: UInt16?
    let options: Data?
    let payload: Data?
    
    init?(data: Data)
    {
        return nil
    }
}

extension Ethernet: MaybeDatable
{
    init?(data: Data) {
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        guard let preamble = bits.unpack(bytes: 7) else { return nil }
        self.preamble = preamble
        
        guard let startDelimiter = bits.unpack(bytes: 1) else { return nil }
        self.startDelimiter = startDelimiter[0]
        
        guard let MACDestination = bits.unpack(bytes: 6) else { return nil }
        self.MACDestination = MACDestination
        
        guard let MACSource = bits.unpack(bytes: 6) else { return nil }
        self.MACSource = MACSource
        
        guard let tag = bits.unpack(bytes: 4) else { return nil }
        self.tag = tag
        
        guard let length = bits.unpack(bytes: 2) else { return nil }
        self.length = UInt16(data: length)
        
        guard let payload = bits.unpack(bytes: Int(self.length)) else { return nil }
        self.payload = payload
        
        guard let crc = bits.unpack(bytes: 4) else { return nil }
        self.crc = UInt32(data: crc)
    }
    
    var data: Data {
        DatableConfig.endianess = .little
        var result = Data()
        result.append(preamble)
        result.append(startDelimiter)
        result.append(MACDestination)
        result.append(MACSource)
        
        if let t = tag
        {
            result.append(t)
        }
        
        result.append(length.data)
        result.append(payload)
        result.append(crc.data)
        
        return result
    }
}

//extension TCP: MaybeDatable
//{
//    init?(data: Data) {
//        <#code#>
//    }
//
//    var data: Data {
//        <#code#>
//    }
//}y
//
//extension TCP: MaybeDatable
//{
//    init?(data: Data) {
//        <#code#>
//    }
//
//    var data: Data {
//        <#code#>
//    }
//}

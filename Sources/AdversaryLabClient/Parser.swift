//
//  Parser.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/9/20.
//

import Foundation
import Datable

public typealias UInt2 = UInt8
public typealias UInt3 = UInt8
public typealias UInt4 = UInt8
public typealias UInt5 = UInt8
public typealias UInt6 = UInt8
public typealias UInt7 = UInt8

public typealias UInt9 = UInt16
public typealias UInt10 = UInt16
public typealias UInt11 = UInt16
public typealias UInt12 = UInt16
public typealias UInt13 = UInt16

// IEEE 802.3 Ethernet frame
public struct Ethernet
{
    public let preamble: Data // 7 bytes
    public let startDelimiter: UInt8 // 1 byte
    public let MACDestination: Data // 6 bytes
    public let MACSource: Data // 6 bytes
    public let tag: Data? // 4 bytes
    public let length: UInt16
    public let payload: Data // variable, 46-1500 bytes, specified by length
    public let crc: UInt32
}

public struct IPv4
{
    public let version: UInt4
    public let IHL: UInt4
    public let DSCP: UInt6
    public let ECN: UInt2
    public let length: UInt16
    public let identification: UInt16
    public let flags: UInt3
    public let fragmentOffset: UInt13
    public let ttl: UInt8
    public let protocolNumber: UInt8
    public let checksum: UInt16
    public let sourceAddress: UInt32
    public let destinationAddress: UInt32
    public let options: UInt64?
    public let payload: Data?
}

public struct TCP
{
    public let sourcePort: UInt16
    public let destinationPort: UInt16
    public let sequenceNumber: UInt32
    public let acknowledgementNumber: UInt32?
    public let offset: UInt4
    public let ns: Bool
    public let cwr: Bool
    public let ece: Bool
    public let urg: Bool
    public let ack: Bool
    public let psh: Bool
    public let rst: Bool
    public let syn: Bool
    public let fin: Bool
    public let windowSize: UInt16
    public let checksum: UInt16
    public let urgentPointeR: UInt16?
    public let options: Data?
    public let payload: Data?
    
    public init?(data: Data)
    {
        return nil
    }
}

extension Ethernet: MaybeDatable
{
    public init?(data: Data) {
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
    
    public var data: Data {
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

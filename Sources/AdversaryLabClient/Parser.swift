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
//    public let preamble: Data // 7 bytes
//    public let startDelimiter: UInt8 // 1 byte
    public let MACDestination: Data // 6 bytes
    public let MACSource: Data // 6 bytes
    public let type: Data // 2 bytes
    public let tag: Data? // 4 bytes
    //public let length: UInt16
    public let payload: Data // variable, 46-1500 bytes, specified by length
    //public let crc: UInt32 // 4 bytes
}

public struct IPv4
{
//    public let version: UInt4
//    public let IHL: UInt4
//    public let DSCP: UInt6
//    public let ECN: UInt2
//    public let length: UInt16
//    public let identification: UInt16
//    public let flags: UInt3
//    public let fragmentOffset: UInt13
//    public let ttl: UInt8
//    public let protocolNumber: UInt8
//    public let checksum: UInt16
//    public let sourceAddress: UInt32
//    public let destinationAddress: UInt32
//    public let options: UInt64?
//    public let payload: Data?
    
    //the type for each probably needs to be changed:
    public let version: Data //4 bits
    public let IHL: Data //4 bits
    public let DSCP: Data //6 bits
    public let ECN: Data //2 bits
    public let length: Data //2 bytes
    public let identification: Data //2 bytes
    public let flags: Data //3 bits
    public let fragmentOffset: Data //13 bits
    public let ttl: Data //1 byte
    public let protocolNumber: Data //1 byte
    public let checksum: Data //2 bytes
    public let sourceAddress: Data //4 bytes
    public let destinationAddress: Data //4 bytes
    public let options: Data //16 bytes
    public let payload: Data
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
        
        guard let MACDestination = bits.unpack(bytes: 6) else { return nil }
        self.MACDestination = MACDestination
        print("\ndst: ", terminator: "")
        for byte in self.MACDestination {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        guard let MACSource = bits.unpack(bytes: 6) else { return nil }
        self.MACSource = MACSource
        print("\nsrc: ", terminator: "")
        for byte in self.MACSource{
            print(String(format: "%02x", byte), terminator: ":")
        }
       
        
        guard let type = bits.unpack(bytes: 2) else { return nil }
        print("\ntype: ", terminator: "")
        for byte in type{
            print(String(format: "%02x", byte), terminator: " ")
        }
        
        if type[1] == 0x81 && type[0] == 0x00 { //vlan tag 802.1Q, type=0x8100
            guard let tag2 = bits.unpack(bytes: 2) else { return nil } //collect 2nd half of tag
            
            
            //combine type and tag2 then store in self.tag
            //setting to nil for now, this needs to be replaced
            self.tag = nil
            
            //update type since this frame has 802.1Q tagging and type comes after the tag
            guard let type = bits.unpack(bytes: 2) else { return nil }
            self.type = type
            
        } else {
            self.type = type
            self.tag = nil
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
//        print("\npay: ", terminator: "")
//        for byte in self.payload{
//            print(String(byte, radix:16), terminator: ":")
//        }
        
        
 
    }
    
    public var data: Data {
        DatableConfig.endianess = .little
        var result = Data()
        //result.append(preamble)
        //result.append(startDelimiter)
        result.append(MACDestination)
        result.append(MACSource)
        
        if let t = tag
        {
            result.append(t)
        }
        
        //result.append(length.data)
        result.append(payload)
        //result.append(crc.data)
        
        return result
    }
}

extension IPv4: MaybeDatable
{
    public init?(data: Data) {
        print("init")
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        guard let version = bits.unpack(bits: 4) else { return nil }
        guard let IHL = bits.unpack(bits: 4) else { return nil }
        
        guard let DSCP = bits.unpack(bits: 6) else { return nil }
        guard let ECN = bits.unpack(bits: 2) else { return nil }
        
        guard let length = bits.unpack(bytes: 2) else { return nil }
        guard let identification = bits.unpack(bytes: 2) else { return nil }
        
        guard let flags = bits.unpack(bits: 3) else { return nil }
        guard let fragmentOffset = bits.unpack(bits: 13) else { return nil }

        guard let ttl = bits.unpack(bytes: 1) else { return nil }
        guard let protocolNumber = bits.unpack(bytes: 1) else { return nil }
        guard let checksum = bits.unpack(bytes: 2) else { return nil }
        guard let sourceAddress = bits.unpack(bytes: 4) else { return nil }
        guard let destinationAddress = bits.unpack(bytes: 4) else { return nil }
        
        
        //set all to 'data' just to get it to compile
        self.version = data
        self.IHL = data
        self.DSCP = data
        self.ECN = data
        self.length = data
        self.identification = data
        self.flags = data
        self.fragmentOffset = data
        self.ttl = data
        self.protocolNumber = data
        self.checksum = data
        self.sourceAddress = data
        self.destinationAddress = data
        self.options = data
        self.payload = data
        
        
    }

    public var data: Data {
        DatableConfig.endianess = .little
        var result = Data()
        result.append(version)
        result.append(IHL)
        result.append(DSCP)
        result.append(ECN)
        result.append(length)
        result.append(identification)
        result.append(flags)
        result.append(fragmentOffset)
        result.append(ttl)
        result.append(protocolNumber)
        result.append(checksum)
        result.append(sourceAddress)
        result.append(destinationAddress)
        result.append(options) //add conditional
        result.append(payload)
        
        return result
    }
}
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

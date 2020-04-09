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
    public let MACDestination: Data // 6 bytes
    public let MACSource: Data // 6 bytes
    public let type: EtherType // 2 bytes
    public let tag1: Data? // 4 bytes
    public let tag2: Data? // 4 bytes
    public let payload: Data // variable, 46-1500 bytes, specified by length
}

public enum EtherType: Int {
    case IPv4 = 0x0800    //Internet Protocol version 4 (IPv4)
    case rev4vPI = 0x0080
    case ARP = 0x0806    //Address Resolution Protocol (ARP)
    case IPv6 = 0x86DD    //Internet Protocol Version 6 (IPv6)
    case singleTagVLAN = 0x8100    //VLAN-tagged frame (IEEE 802.1Q)
    case doubleTagVLAN = 0x9100    //VLAN-tagged (IEEE 802.1Q) frame with double tagging
}

public extension EtherType {
    
    init?(data: Data) {
        DatableConfig.endianess = .big
        let x = Int(data.uint16)
        self.init(rawValue: x)
    }
    
    var data: Data? {
        DatableConfig.endianess = .big
        let x = self.rawValue
        return Data(uint16: UInt16(x))
    }
    
}

public struct IPv4
{
    //http://www.networksorcery.com/enp/protocol/ip.htm
    
    public let version: UInt8 //4 bits
    public let IHL: UInt8 //4 bits
    public let DSCP: UInt8 //6 bits
    public let ECN: UInt8 //2 bits
    public let length: UInt16 //2 bytes   --number
    public let identification: UInt16 //2 bytes
    public let flags: UInt8 //3 bits
    public let fragmentOffset: UInt16 //13 bits   --number
    public let ttl: UInt8 //1 byte   --number
    public let protocolNumber: UInt8 //1 byte
    public let checksum: UInt16 //2 bytes
    public let sourceAddress: Data //4 bytes
    public let destinationAddress: Data //4 bytes
    public let options: Data? //up to 32 bytes
    public let payload: Data
}

public enum IPversion: Int {
    case IPv4 = 4
    case IPv6 = 6
}

extension IPversion {
    public init?(bits: Bits) {
        guard let x = bits.int else {return nil}
        self.init(rawValue: x)
    }
    
    public var bits: Bits? {
        let x = self.rawValue
        return Bits(int: x)
    }
    
}


public enum IPprotocolNumber: Int {
     //https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers
     case ICMP = 0x01
     case TCP = 0x06 //priority
     case UDP = 0x11
     case RDP = 0x1B
     case IPv6 = 0x29
     case L2TP = 0x73
     case SCTP = 0x84
}

extension IPprotocolNumber{
    init?(data: Data) {
        let x = data.int
        self.init(rawValue: x)
    }
    
    var data: Data? {
        let x = self.rawValue
        return Data(int: x)
    }
    
}



public struct TCP
{
    public let sourcePort: UInt16
    public let destinationPort: UInt16
    public let sequenceNumber: Data
    public let acknowledgementNumber: Data?
    public let offset: UInt8
    public let ns: Bool
    public let cwr: Bool
    public let ece: Bool
    public let urg: Bool
    public let ack: Bool
    public let psh: Bool
    public let rst: Bool
    public let syn: Bool
    public let fin: Bool
    public let windowSize: Data
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
       
        // links for type or tag documentation
        // https://en.wikipedia.org/wiki/IEEE_802.1Q
        // https://en.wikipedia.org/wiki/EtherType
        guard let typeOrTagPrefix = bits.unpack(bytes: 2) else { return nil }
        print("\ntypeOrTagPrefix: ", terminator: "")
        for byte in typeOrTagPrefix {
            print(String(format: "%02x", byte), terminator: " ")
        }
        DatableConfig.endianess = .big
        let typeOrTagUInt16 = typeOrTagPrefix.uint16
        print(" -- \(typeOrTagUInt16)")
        DatableConfig.endianess = .little
        
        
        if typeOrTagUInt16 == 0x8100 {
            //type is really vlan tag 802.1Q, type=0x8100
            guard let tag2 = bits.unpack(bytes: 2) else { return nil } //collect 2nd half of tag
            
            //Combine type and tag2 then store in self.tag1
            var tempTag = typeOrTagPrefix
            tempTag.append(tag2.data)
            self.tag1 = tempTag.data
            
            //update the type since this frame has 802.1Q tagging and type comes after the tag
            guard let type = bits.unpack(bytes: 2) else { return nil }
            
            guard let tempType = EtherType(data: type) else {
                print("\n1 Failed EtherType conversion - Ethernet Packet Type: \(type as! NSData)")
                return nil
            }
            
            self.type = tempType
            self.tag2 = nil
            
        } else if typeOrTagUInt16 == 0x88a8 {
            //fix this, add double tag parsing
            //802.1Q double tagged 0x88a8 -- confirm it's not 0x9100
            //read 2 bytes combine with typeOrTagPrefix and store in tag1
            //read 4 bytes and store as tag2, first 2 bytes should be 0x8100
            //read 2 bytes and assign to self.type
            self.tag2 = nil
            print("!! 802.1Q double tag not parsed !!")
            return nil
            
        } else if typeOrTagUInt16 == 0x0800 {
            guard let tempType = EtherType(data: typeOrTagPrefix) else {
                print("\n2 Failed EtherType conversion - Ethernet Packet Type: \(typeOrTagPrefix as! NSData)")
                return nil
            }
            self.tag1 = nil
            self.tag2 = nil
            self.type = tempType
            
        } else {
            guard let tempType = EtherType(data: typeOrTagPrefix) else {
                print("\n3 Failed EtherType conversion - Ethernet Packet Type: \(typeOrTagPrefix as! NSData)\n")
                return nil
            }
            self.type = tempType
            self.tag1 = nil
            self.tag2 = nil
            
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
        
    }
    
    public var data: Data {
        DatableConfig.endianess = .little
        var result = Data()

        result.append(MACDestination)
        result.append(MACSource)
        
        if let t = tag1
        {
            result.append(t)
        }

        result.append(payload)
        
        return result
    }
}

extension IPv4: MaybeDatable
{
    public init?(data: Data) {
        
        print("start parsing IPv4")
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        guard let version = bits.unpack(bits: 4) else { return nil }
        self.version = version.uint8!
        print("\nVersion: ", terminator: "")
        print(String(format: "%02x", self.version), terminator: "")
        
        guard let IHL = bits.unpack(bits: 4) else { return nil }
        self.IHL = IHL.uint8!
        print("\nIHL: ", terminator: "")
        print(String(format: "%02x", self.IHL), terminator: "")

        guard let DSCP = bits.unpack(bits: 6) else { return nil }
        self.DSCP = DSCP.uint8!
        print("\nDSCP: ", terminator: "")
        print(String(format: "%02x", self.DSCP), terminator: "")
        
        guard let ECN = bits.unpack(bits: 2) else { return nil }
        self.ECN = ECN.uint8!
        print("\nECN: ", terminator: "")
        print(String(format: "%02x", self.ECN), terminator: "")
        
        guard let length = bits.unpack(bytes: 2) else {
            print("\n\nFail IPv4 length")
            return nil
        }
        self.length = length.uint16
        print("\nLength: ", terminator: "")
        print(String(format: "%02x", self.length), terminator: "")
        
        guard let identification = bits.unpack(bytes: 2) else { return nil }
        self.identification = identification.uint16
        print("\nIdentification: ", terminator: "")
        print(String(format: "%02x", self.identification), terminator: "")
        
        guard let flags = bits.unpack(bits: 3) else { return nil }
        self.flags = flags.uint8!
        print("\nFlags: ", terminator: "")
        print(String(format: "%02x", self.flags), terminator: "")
        
        guard let fragmentOffset = bits.unpack(bits: 13) else { return nil }
        self.fragmentOffset = fragmentOffset.uint16!
        print("\nFragmentOffset: ", terminator: "")
        print(String(format: "%02x", self.fragmentOffset), terminator: "")

        guard let ttl = bits.unpack(bytes: 1) else { return nil }
        self.ttl = ttl.uint8
        print("\nTTL: ", terminator: "")
        print(String(format: "%02x", self.ttl), terminator: "")
        
        guard let protocolNumber = bits.unpack(bytes: 1) else { return nil }
        self.protocolNumber = protocolNumber.uint8
        print("\nProtocolNumber: ", terminator: "")
        print(String(format: "%02x", self.protocolNumber), terminator: "")
        
        guard let checksum = bits.unpack(bytes: 2) else { return nil }
        self.checksum = checksum.uint16
        print("\nChecksum: ", terminator: "")
        print(String(format: "%02x", self.checksum), terminator: "")
        
        guard let sourceAddress = bits.unpack(bytes: 4) else { return nil }
        self.sourceAddress = sourceAddress.data
        print("\nsourceAddress: ", terminator: "")
        for byte in self.sourceAddress {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        guard let destinationAddress = bits.unpack(bytes: 4) else { return nil }
        self.destinationAddress = destinationAddress.data
        print("\ndestinationAddress: ", terminator: "")
        for byte in self.destinationAddress {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        print("start parse checks")
        // do options exist?
        if IHL.int ?? 0 > 5{
            //FIX, add code to parse options field
            print("!! IPv4 parsing, IHL > 5, need to parse options field in IP header")
            return nil
            self.options = nil
        } else {
            self.options = nil
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
        var count = 0
        print("\npayload:")
        for byte in self.payload{
            print(String(format: "%02x", byte), terminator: " ")
            count += 1
            if count % 8 == 0{
                print(" ", terminator: "")
            }
            if count % 16 == 0{
                print("")
            }
        }
    }

    public var data: Data {
        DatableConfig.endianess = .little
        var result = Data()
        result.append(version.data)
        result.append(IHL)
        result.append(DSCP)
        result.append(ECN)
        result.append(length.data)
        result.append(identification.data)
        result.append(flags)
        result.append(fragmentOffset.data)
        result.append(ttl)
        result.append(protocolNumber)
        result.append(checksum.data)
        result.append(sourceAddress)
        result.append(destinationAddress)
        result.append(options ?? 0x00.data) //fix
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

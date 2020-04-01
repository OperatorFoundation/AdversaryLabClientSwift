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
        print("\nforce conv \(data as! NSData)")
        let x = data.int
        print(x)
        self.init(rawValue: x)
    }
    
    var data: Data? {
        let x = self.rawValue
        return Data(int: x)
    }
    
}

public struct IPv4
{
    //http://www.networksorcery.com/enp/protocol/ip.htm
    
    public let version: Data //4 bits
    public let IHL: Data //4 bits
    public let DSCP: Data //6 bits
    public let ECN: Data //2 bits
    public let length: UInt16 //2 bytes   --number
    public let identification: Data //2 bytes
    public let flags: Data //3 bits
    public let fragmentOffset: UInt16 //13 bits   --number
    public let ttl: UInt8 //1 byte   --number
    public let protocolNumber: Data //1 byte
    public let checksum: Data //2 bytes
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
       
        // https://en.wikipedia.org/wiki/IEEE_802.1Q
        // https://en.wikipedia.org/wiki/EtherType
        guard let typeOrTagPrefix = bits.unpack(bytes: 2) else { return nil }
        print("\ntypeOrTagPrefix: ", terminator: "")
        for byte in typeOrTagPrefix {
            print(String(format: "%02x", byte), terminator: " ")
        }
        print("\n---")
        print(String(format: "%02x", typeOrTagPrefix[1]))
        print(String(format: "%02x", typeOrTagPrefix[0]))
        print("---")
        if typeOrTagPrefix[0] == 0x81 && typeOrTagPrefix[1] == 0x00 {
            print("\ntypeOrTagPrefix")
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
            
        } else if typeOrTagPrefix[0] == 0x88 && typeOrTagPrefix[1] == 0xa8 {
            //fix this
            //802.1Q double tagged 0x88a8 -- confirm it's not 0x9100
            //read 2bytes combine with typeOrTagPrefix and store in tag1
            //read 4 bytes and store as tag2, first 2 bytes should be 0x8100
            //read 2 bytes and assign to self.type
            self.tag2 = nil
            print("!! 802.1Q double tag not parsed !!")
            return nil
            
        } else if typeOrTagPrefix[0] == 0x08 && typeOrTagPrefix[1] == 0x00
        {
            //self.type = Ethertype(data: typeOrTagPrefix)
            print("\n convert to ethertype")
            guard let tempType = EtherType(data: typeOrTagPrefix) else {
                print("\n2 Failed EtherType conversion - Ethernet Packet Type: \(typeOrTagPrefix as! NSData)")
                //self.type = nil
                return nil
            }
            self.tag1 = nil
            self.tag2 = nil
            self.type = tempType
            
            
        }else{
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
//        print("\npayload\n: ", terminator: "")
//        for byte in self.payload{
//            print(String(byte, radix:16), terminator: ":")
//        }
        
        
 
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
        
        //options?
        if IHL.int ?? 0 > 5{
            //fix, add code to parse options field
            print("!! IHL > 5, need to parse options field in IP header")
            self.options = nil
        } else {
            self.options = nil
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        
        
        self.version = version.buffer
        print("\nver: ", terminator: "")
        for byte in self.version {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.IHL = IHL.data
        print("\nIHL: ", terminator: "")
        for byte in self.IHL {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.DSCP = DSCP.data
        print("\nDSCP: ", terminator: "")
        for byte in self.DSCP {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.ECN = ECN.data
        print("\nECN: ", terminator: "")
        for byte in self.ECN {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.length = length.uint16
        print("\nLength: ", terminator: "")
        print(String(format: "%02x", self.length), terminator: "")
        
        
        self.identification = identification
        print("\nident: ", terminator: "")
        for byte in self.identification {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.flags = flags.data
        print("\nflags: ", terminator: "")
        for byte in self.flags {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.fragmentOffset = fragmentOffset.uint16 ?? 0xFFFF
        print("\nfragmentOffset: ", terminator: "")
        print(String(format: "%02x", self.fragmentOffset), terminator: "")

        
        self.ttl = ttl.uint8
        print("\nttl: ", terminator: "")
        print(String(format: "%02x", self.ttl), terminator: "")
        
        self.protocolNumber = protocolNumber
        print("\nprotocolNumber: ", terminator: "")
        for byte in self.protocolNumber {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.checksum = checksum
        print("\nchecksum: ", terminator: "")
        for byte in self.checksum {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.sourceAddress = sourceAddress
        print("\nsourceAddress: ", terminator: "")
        for byte in self.sourceAddress {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        self.destinationAddress = destinationAddress
        print("\ndestinationAddress: ", terminator: "")
        for byte in self.destinationAddress {
            print(String(format: "%02x", byte), terminator: ":")
        }
        
        //self.options = data
        
        
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
        result.append(version)
        result.append(IHL)
        result.append(DSCP)
        result.append(ECN)
        result.append(length.data)
        result.append(identification)
        result.append(flags)
        result.append(fragmentOffset.data)
        result.append(ttl)
        result.append(protocolNumber)
        result.append(checksum)
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

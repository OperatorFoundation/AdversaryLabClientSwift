//
//  Parser.swift
//
//
//  Created by Dr. Brandon Wiley on 3/9/20.
//

import Foundation
import Datable

public func printDataBytes(bytes: Data, hexDumpFormat: Bool, seperator: String, decimal: Bool)
{
    if hexDumpFormat
    {
        var count = 0
        for byte in bytes
        {
            print(String(format: "%02x", byte), terminator: " ")
            count += 1
            if count % 8 == 0
            {
                print(" ", terminator: "")
            }
            if count % 16 == 0
            {
                print("")
            }
        }
    }
    else
    {
        var i = 0
        for byte in bytes
        {
            if decimal
            {
                print(String(format: "%u", byte), terminator: "")
            }
            else
            {
                print(String(format: "%02x", byte), terminator: "")
            }
            i += 1
            if i < bytes.count { print(seperator, terminator: "") }
        }
    }
    print("")
}

public struct Packet
{
    public let rawBytes: Data
    public let timestamp: Int //time in milliseconds since unix epoch
    public var ethernet: Ethernet?
    public var ipv4: IPv4?
    public var tcp: TCP?
    public var udp: UDP?
    
    public init(rawBytes: Data)
    {
        self.rawBytes = rawBytes
        self.timestamp = Int(Date().timeIntervalSince1970 * 1e3) //converting from seconds to milliseconds
        
        if let ethernetPacket = Ethernet(data: rawBytes)
        {
            self.ethernet = ethernetPacket
            if let IPv4Packet = IPv4(data: ethernetPacket.payload)
            {
                self.ipv4 = IPv4Packet
                
                if let payload = IPv4Packet.payload
                {
                    if let TCPsegment = TCP(data: payload)
                    {
                        self.tcp = TCPsegment
                    }
                    
                    if let UDPsegment = UDP(data: payload)
                    {
                        self.udp = UDPsegment
                    }
                }
            }
        }
    }
}

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

public enum EtherType: UInt16
{
    case IPv4 = 0x0800    //Internet Protocol version 4 (IPv4)
    case rev4vPI = 0x0080
    case ARP = 0x0806    //Address Resolution Protocol (ARP)
    case IPv6 = 0x86DD    //Internet Protocol Version 6 (IPv6)
    case singleTagVLAN = 0x8100    //VLAN-tagged frame (IEEE 802.1Q)
    case doubleTagVLAN = 0x9100    //VLAN-tagged (IEEE 802.1Q) frame with double tagging
}

public extension EtherType
{
    init?(data: Data)
    {
        DatableConfig.endianess = .big
        let x = UInt16(data.uint16)
        self.init(rawValue: x)
    }
    
    var data: Data?
    {
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
    public let reservedBit: UInt8 //1 bit
    public let dontFragment: UInt8 //1 bit
    public let moreFragments: UInt8 //1 bit
    public let fragmentOffset: UInt16 //13 bits   --number
    public let ttl: UInt8 //1 byte   --number
    public let protocolNumber: IPprotocolNumber //UInt8 //1 byte
    public let checksum: UInt16 //2 bytes
    public let sourceAddress: Data //4 bytes
    public let destinationAddress: Data //4 bytes
    public let options: Data? //up to 32 bytes
    public let payload: Data?
}

public struct IPv6
{
    public let version: UInt8 //4 bits
    public let trafficClass: UInt8 //8 bits
    public let flowLabel: UInt32//20bits
    public let payloadLength: UInt16 //2 bytes
    public let nextHeader: UInt8 //1 byte
    public let hopLimit: UInt8 //1 byte
    public let sourceAddress: Data //16 bytes
    public let destinationAddress: Data //16 bytes
    //options?
    public let payload: Data
}

public enum IPversion: Int
{
    case IPv4 = 4
    case IPv6 = 6
}

extension IPversion
{
    public init?(bits: Bits)
    {
        guard let x = bits.int else { return nil }
        self.init(rawValue: x)
    }
    
    public var bits: Bits?
    {
        let x = self.rawValue
        return Bits(int: x)
    }
    
}

public enum IPprotocolNumber: UInt8
{
    //https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers
    case ICMP = 0x01
    case TCP = 0x06 //first
    case UDP = 0x11 //second
    case RDP = 0x1B
    case IPv6 = 0x29 //third
    case L2TP = 0x73
    case SCTP = 0x84
    
    //IPv6 options:
    case HOPOPT = 0x00 //IPv6 Hop-by-Hop Option
    case IPv6Route = 0x2B //Routing Header for IPv6
    case IPv6Frag = 0x2C //Fragment Header for IPv6
    case ESP = 0x32 //Encapsulating Security Payload
    case AH = 0x33 //Authentication Header
    case IPv6Opts = 0x3C//Destination Options for IPv6
    case MobilityHeader = 0x87 //Mobility Extension Header for IPv6
    case HIP = 0x8B //Host Identity Protocol
    case Shim6 = 0x8C //Site Multihoming by IPv6 Intermediation
    //expiramental 0xFD & 0xFE
}

extension IPprotocolNumber
{
    init?(data: Data)
    {
        let x = data.uint8
        self.init(rawValue: x)
    }
    
    var data: Data?
    {
        let x = self.rawValue
        return Data(uint8: x)
    }
    
}

public struct TCP
{
    public let sourcePort: UInt16
    public let destinationPort: UInt16
    public let sequenceNumber: Data
    public let acknowledgementNumber: Data
    public let offset: UInt8
    public let reserved: UInt8
    public let ns: UInt8 //Bool
    public let cwr: UInt8 //Bool
    public let ece: UInt8 //Bool
    public let urg: UInt8 //Bool
    public let ack: UInt8 //Bool
    public let psh: UInt8 //Bool
    public let rst: UInt8 //Bool
    public let syn: UInt8 //Bool
    public let fin: UInt8 //Bool
    public let windowSize: UInt16
    public let checksum: UInt16
    public let urgentPointer: UInt16
    public let options: Data?
    public let payload: Data?
}

public struct UDP
{
    public let sourcePort: UInt16
    public let destinationPort: UInt16
    public let length: UInt16
    public let checksum: UInt16
    public let payload: Data?
}

extension Ethernet: MaybeDatable
{
    public init?(data: Data)
    {
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        guard let MACDestination = bits.unpack(bytes: 6) else { return nil }
        self.MACDestination = MACDestination
        print("dst: ", terminator: "")
        printDataBytes(bytes: self.MACDestination, hexDumpFormat: false, seperator: ":", decimal: false)
        
        guard let MACSource = bits.unpack(bytes: 6) else { return nil }
        self.MACSource = MACSource
        print("src: ", terminator: "")
        printDataBytes(bytes: self.MACSource, hexDumpFormat: false, seperator: ":", decimal: false)
        
        // links for type or tag documentation
        // https://en.wikipedia.org/wiki/IEEE_802.1Q
        // https://en.wikipedia.org/wiki/EtherType
        guard let typeOrTagPrefix = bits.unpack(bytes: 2) else { return nil }
        print("typeOrTagPrefix: 0x", terminator: "")
        printDataBytes(bytes: typeOrTagPrefix, hexDumpFormat: false, seperator: "", decimal: false)
        
        DatableConfig.endianess = .big
        let typeOrTagUInt16 = typeOrTagPrefix.uint16
        print("typeOrTagPrefix: 0xd\(typeOrTagUInt16)")
        DatableConfig.endianess = .little
        
        if typeOrTagUInt16 == 0x8100
        {
            //type is really vlan tag 802.1Q, type=0x8100
            guard let tag2 = bits.unpack(bytes: 2) else { return nil } //collect 2nd half of tag
            
            //Combine type and tag2 then store in self.tag1
            //fix, should the tag be both the 0x8100 and VLAN ID?
            var tempTag = typeOrTagPrefix
            tempTag.append(tag2.data)
            self.tag1 = tempTag.data
            
            //update the type since this frame has 802.1Q tagging and type comes after the tag
            guard let type = bits.unpack(bytes: 2) else { return nil }
            
            guard let tempType = EtherType(data: type) else { return nil }
            
            self.type = tempType
            self.tag2 = nil
        }
            //fix double tagging
            //        else if typeOrTagUInt16 == 0x88a8 { // fix what about 0x9100 seems that's also a doubletagged frame
            //            //fix this, add double tag parsing
            //            //802.1Q double tagged 0x88a8 -- confirm it's not 0x9100
            //            //read 2 bytes combine with typeOrTagPrefix and store in tag1
            //            //read 4 bytes and store as tag2, first 2 bytes should be 0x8100
            //            //read 2 bytes and assign to self.type
            //            self.tag2 = nil
            //            print("!! 802.1Q double tag not parsed !!")
            //            return nil
            //
            //        }
        else if typeOrTagUInt16 == 0x0800
        {
            let tempType = EtherType(data: typeOrTagPrefix)! //force unwrap ok because typeOrTagPrefix can't be nil because "let typeOrTagUInt16 = typeOrTagPrefix.uint16" and typeOrTagPrefix is 0x0800 per the above if
            self.tag1 = nil
            self.tag2 = nil
            self.type = tempType
        }
        else
        {
            guard let tempType = EtherType(data: typeOrTagPrefix) else
            {
                //print("3 Failed EtherType conversion - Ethernet Packet Type: \(typeOrTagPrefix as! NSData)")
                return nil
            }
            self.type = tempType
            self.tag1 = nil
            self.tag2 = nil
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
    }
    
    
    
    public var data: Data
    {
        DatableConfig.endianess = .big
        var result = Data()
        
        result.append(MACDestination)
        result.append(MACSource)
        
        if let typeData = type.data
        {
            result.append(typeData)
        }
        
        if let t = tag1
        {
            result.append(t)
        }
        
        if let t = tag2
        {
            result.append(t)
        }
        
        result.append(payload)
        
        return result
    }
}

extension IPv4: MaybeDatable
{
    public init?(data: Data)
    {
        print("start parsing IPv4")
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        //unpack a byte then parse into bits
        guard let VerIHL = bits.unpack(bytes: 1) else { return nil }
        var VerIHLbits = Bits(data: VerIHL)
        guard let version = VerIHLbits.unpack(bits: 4) else { return nil }
        guard let versionUint8 = version.uint8 else { return nil }
        self.version = versionUint8
        print("Version: 0x" + String(format: "%02x", self.version))
        
        guard let IHL = VerIHLbits.unpack(bits: 4) else { return nil }
        guard let IHLUint8 = IHL.uint8 else { return nil }
        self.IHL = IHLUint8
        print("IHL: 0x" + String(format: "%02x", self.IHL))
        
        guard let DSCPECN = bits.unpack(bytes: 1) else { return nil }
        var DSCPECNbits = Bits(data: DSCPECN)
        guard let DSCP = DSCPECNbits.unpack(bits: 6) else { return nil }
        guard let DSCPUint8 = DSCP.uint8 else { return nil }
        self.DSCP = DSCPUint8
        print("DSCP: 0x" + String(format: "%02x", self.DSCP))
        
        guard let ECN = DSCPECNbits.unpack(bits: 2) else { return nil }
        guard let ECNUint8 = ECN.uint8 else { return nil }
        self.ECN = ECNUint8
        print("ECN: 0x" + String(format: "%02x", self.ECN))
        
        DatableConfig.endianess = .big
        guard let length = bits.unpack(bytes: 2) else { return nil }
        let lengthUint16 = length.uint16
        self.length = lengthUint16
        print("Length: 0x" + String(format: "%02x", self.length) + " - 0d" + String(format: "%u", self.length))
        
        guard let identification = bits.unpack(bytes: 2) else { return nil }
        let identificationUint16 = identification.uint16
        self.identification = identificationUint16
        print("Identification: 0x" + String(format: "%02x", self.identification))
        DatableConfig.endianess = .little
        
        guard let flagsFragmentOffset = bits.unpack(bytes: 2) else { return nil }
        var flagsFragmentOffsetbits = Bits(data: flagsFragmentOffset)
        
        guard let reservedBit = flagsFragmentOffsetbits.unpack(bits: 1) else { return nil }
        guard let dontFragment = flagsFragmentOffsetbits.unpack(bits: 1) else { return nil }
        guard let moreFragments = flagsFragmentOffsetbits.unpack(bits: 1) else { return nil }
        
        guard let reservedBitUint8 = reservedBit.uint8 else { return nil }
        guard let dontFragmentUint8 = dontFragment.uint8 else { return nil }
        guard let moreFragmentsUint8 = moreFragments.uint8 else { return nil }
        
        self.reservedBit = reservedBitUint8
        self.dontFragment = dontFragmentUint8
        self.moreFragments = moreFragmentsUint8
        
        print("reservedBit: 0x" + String(format: "%02x", self.reservedBit) + " - 0b" + String(self.reservedBit, radix: 2))
        print("dontFragment: 0x" + String(format: "%02x", self.dontFragment) + " - 0b" + String(self.dontFragment, radix: 2))
        print("moreFragments: 0x" + String(format: "%02x", self.moreFragments) + " - 0b" + String(self.moreFragments, radix: 2))
        
        guard let fragmentOffset = flagsFragmentOffsetbits.unpack(bits: 13) else { return nil }
        guard let fragmentOffsetUint16 = fragmentOffset.uint16 else { return nil }
        self.fragmentOffset = fragmentOffsetUint16
        print("FragmentOffset: 0d" + String(format: "%u", self.fragmentOffset))
        
        guard let ttl = bits.unpack(bytes: 1) else { return nil }
        let ttlUint8 = ttl.uint8
        self.ttl = ttlUint8
        print("TTL: 0d" + String(format: "%u", self.ttl))
        
        guard let protocolNumber = bits.unpack(bytes: 1) else { return nil } //fix should use IPprotocolNumber()
        let protocolNumberUint8 = protocolNumber.uint8
        print("ProtocolNumber: 0d" + String(format: "%u", protocolNumberUint8 ))
        guard let protocolNumType = IPprotocolNumber(data: protocolNumber) else { return nil }
        self.protocolNumber = protocolNumType
        
        
        DatableConfig.endianess = .big
        guard let checksum = bits.unpack(bytes: 2) else { return nil }
        let checksumUint16 = checksum.uint16
        self.checksum = checksumUint16
        print("Checksum: 0x" + String(format: "%02x", self.checksum))
        DatableConfig.endianess = .little
        
        guard let sourceAddress = bits.unpack(bytes: 4) else { return nil }
        self.sourceAddress = sourceAddress.data
        print("sourceAddress: ", terminator: "")
        
        printDataBytes(bytes: self.sourceAddress, hexDumpFormat: false, seperator: ".", decimal: true)
        
        guard let destinationAddress = bits.unpack(bytes: 4) else { return nil }
        self.destinationAddress = destinationAddress.data
        print("destinationAddress: ", terminator: "")
        printDataBytes(bytes: self.destinationAddress, hexDumpFormat: false, seperator: ".", decimal: true)
        
        if IHLUint8 > 5
        {
            //options exist if IHL > 5, each IHL point is 32 bits (4 bytes), upto IHL = 15 or 320 bits, 40 bytes
            guard let options = bits.unpack(bytes: Int((IHLUint8 - 5) * 4)) else { return nil }
            self.options = options
            print("options:")
            printDataBytes(bytes: options, hexDumpFormat: true, seperator: "", decimal: false)
            return nil
        }
        else
        {
            print("options: nil")
            self.options = nil
        }
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
        print("payload:")
        printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
    }
    
    public var data: Data
    {
        DatableConfig.endianess = .big
        var result = Data()
        result.append(version.data)
        result.append(IHL)
        result.append(DSCP)
        result.append(ECN)
        result.append(length.data)
        result.append(identification.data)
        result.append(reservedBit)
        result.append(dontFragment)
        result.append(moreFragments)
        result.append(fragmentOffset.data)
        result.append(ttl)
        if let protocolNumberData = protocolNumber.data
        {
            result.append(protocolNumberData)
        }
        result.append(checksum.data)
        result.append(sourceAddress)
        result.append(destinationAddress)
        if let optionsData = options
        {
            result.append(optionsData)
        }
        if let realpayload = payload
        {
            result.append(realpayload)
        }
        
        return result
    }
}

extension TCP: MaybeDatable
{
    public init?(data: Data)
    {
        //https://en.wikipedia.org/wiki/Transmission_Control_Protocol#TCP_segment_structure
        //https://tools.ietf.org/html/rfc7414 - roadmap to TCP RFCs
        
        print("start parsing TCP")
        DatableConfig.endianess = .little
        
        var bits = Bits(data: data)
        
        DatableConfig.endianess = .big
        guard let sourcePort = bits.unpack(bytes: 2) else { return nil }
        let sourcePortUint16 = sourcePort.uint16
        self.sourcePort = sourcePortUint16
        print("sourcePort: 0x" + String(format: "%02x", self.sourcePort) + " - 0d" + String(format: "%u", self.sourcePort))
        
        guard let destinationPort = bits.unpack(bytes: 2) else { return nil }
        let destinationPortUint16 = destinationPort.uint16
        self.destinationPort = destinationPortUint16
        print("destPort: 0x" + String(format: "%02x", self.destinationPort) + " - 0d" + String(format: "%u", self.destinationPort))
        DatableConfig.endianess = .little
        
        guard let sequenceNumber = bits.unpack(bytes: 4) else { return nil }
        self.sequenceNumber = sequenceNumber.data
        print("SequenceNum: ", terminator: "")
        printDataBytes(bytes: sequenceNumber, hexDumpFormat: true, seperator: "", decimal: false)
        
        guard let acknowledgementNumber = bits.unpack(bytes: 4) else { return nil }
        self.acknowledgementNumber = acknowledgementNumber.data
        print("acknowledgementNum: ", terminator: "")
        printDataBytes(bytes: acknowledgementNumber, hexDumpFormat: true, seperator: "", decimal: false)
        
        DatableConfig.endianess = .big
        guard let offsetReservedFlags = bits.unpack(bytes: 2) else { return nil }
        var dataReservedFlagsBits = Bits(data: offsetReservedFlags)
        let offsetReservedFlagsUint16 = offsetReservedFlags.uint16
        print("offsetReservedFlags: 0x" + String(format: "%02x", offsetReservedFlagsUint16) + " - 0b" + String(offsetReservedFlagsUint16, radix: 2))
        DatableConfig.endianess = .little
        
        guard let offset = dataReservedFlagsBits.unpack(bits: 4) else { return nil }
        guard let offsetUint8 = offset.uint8 else { return nil }
        self.offset = offsetUint8
        print("Offset: 0x" + String(format: "%02x", self.offset) + " - 0b" + String(self.offset, radix: 2))
        
        guard let reserved = dataReservedFlagsBits.unpack(bits: 3) else { return nil }
        guard let reservedUint8 = reserved.uint8 else { return nil }
        self.reserved = reservedUint8
        print("reserved: 0x" + String(format: "%02x", self.reserved) + " - 0b" + String(self.reserved, radix: 2))
        
        guard let ns = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let nsUint8 = ns.uint8 else { return nil }
        self.ns = nsUint8
        print("ns: 0x" + String(format: "%02x", self.ns) + " - 0b" + String(self.ns, radix: 2))
        
        guard let cwr = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let cwrUint8 = cwr.uint8 else { return nil }
        self.cwr = cwrUint8
        print("cwr: 0x" + String(format: "%02x", self.cwr) + " - 0b" + String(self.cwr, radix: 2))
        
        guard let ece = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let eceUint8 = ece.uint8 else { return nil }
        self.ece = eceUint8
        print("ece: 0x" + String(format: "%02x", self.ece) + " - 0b" + String(self.ece, radix: 2))
        
        guard let urg = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let urgUint8 = urg.uint8 else { return nil }
        self.urg = urgUint8
        print("urg: 0x" + String(format: "%02x", self.urg) + " - 0b" + String(self.urg, radix: 2))
        
        guard let ack = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let ackUint8 = ack.uint8 else { return nil }
        self.ack = ackUint8
        print("ack: 0x" + String(format: "%02x", self.ack) + " - 0b" + String(self.ack, radix: 2))
        
        guard let psh = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let pshUint8 = psh.uint8 else { return nil }
        self.psh = pshUint8
        print("psh: 0x" + String(format: "%02x", self.psh) + " - 0b" + String(self.psh, radix: 2))
        
        guard let rst = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let rstUint8 = rst.uint8 else { return nil }
        self.rst = rstUint8
        print("rst: 0x" + String(format: "%02x", self.rst) + " - 0b" + String(self.rst, radix: 2))
        
        guard let syn = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let synUint8 = syn.uint8 else { return nil }
        self.syn = synUint8
        print("syn: 0x" + String(format: "%02x", self.syn) + " - 0b" + String(self.syn, radix: 2))
        
        guard let fin = dataReservedFlagsBits.unpack(bits: 1) else { return nil }
        guard let finUint8 = fin.uint8 else { return nil }
        self.fin = finUint8
        print("fin: 0x" + String(format: "%02x", self.fin) + " - 0b" + String(self.fin, radix: 2))
        
        DatableConfig.endianess = .big
        guard let windowSize = bits.unpack(bytes: 2) else { return nil }
        let windowSizeUint16 = windowSize.uint16
        self.windowSize = windowSizeUint16
        print("windowSize: 0x" + String(format: "%02x", self.windowSize) + " - 0d" + String(format: "%u", self.windowSize))
        
        guard let checksum = bits.unpack(bytes: 2) else { return nil }
        let checksumUint16 = checksum.uint16
        self.checksum = checksumUint16
        print("checksum: 0x" + String(format: "%02x", self.checksum) + " - 0d" + String(format: "%u", self.checksum))
        
        guard let urgentPointer = bits.unpack(bytes: 2) else { return nil }
        let urgentPointerUint16 = urgentPointer.uint16
        self.urgentPointer = urgentPointerUint16
        print("urgentPointer: 0x" + String(format: "%02x", self.urgentPointer) + " - 0d" + String(format: "%u", self.urgentPointer))
        DatableConfig.endianess = .little
        
        if offsetUint8  > 5 && offsetUint8 < 16
        {
            let bytesToRead = Int((self.offset - 5) * 4)
            guard let options = bits.unpack(bytes: bytesToRead) else { return nil }
            self.options = options.data
            
            print("options:")
            printDataBytes(bytes: options, hexDumpFormat: true, seperator: "", decimal: false)
            
        }
        else
        {
            print("options: nil")
            self.options = nil
        }
        
        if Int(bits.count/8) > 0
        {
            guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
            self.payload = payload
            print("payload:")
            printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
        }
        else
        {
            print("payload: nil")
            self.payload = nil
        }
    }
    
    public var data: Data
    {
        DatableConfig.endianess = .big
        var result = Data()
        result.append(sourcePort.data)
        result.append(destinationPort.data)
        result.append(sequenceNumber.data)
        result.append(acknowledgementNumber.data)
        result.append(offset)
        result.append(reserved)
        result.append(ns)
        result.append(cwr)
        result.append(ece)
        result.append(urg)
        result.append(ack)
        result.append(psh)
        result.append(rst)
        result.append(syn)
        result.append(fin)
        result.append(windowSize.data)
        result.append(checksum.data)
        result.append(urgentPointer.data)
        if let optionsData = options
        {
            result.append(optionsData)
        }
        if let payloadData = payload
        {
            result.append(payloadData)
        }
        return result
    }
}

extension UDP: MaybeDatable
{
    public init?(data: Data)
    {
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        DatableConfig.endianess = .big
        guard let sourcePort = bits.unpack(bytes: 2) else { return nil }
        let sourcePortUint16 = sourcePort.uint16
        self.sourcePort = sourcePortUint16
        print("sourcePort: 0x" + String(format: "%02x", self.sourcePort) + " - 0d" + String(format: "%u", self.sourcePort))
        
        guard let destinationPort = bits.unpack(bytes: 2) else { return nil }
        let destinationPortUint16 = destinationPort.uint16
        self.destinationPort = destinationPortUint16
        print("destinationPort: 0x" + String(format: "%02x", self.destinationPort) + " - 0d" + String(format: "%u", self.destinationPort))
        
        guard let length = bits.unpack(bytes: 2) else { return nil }
        let lengthUint16 = length.uint16
        self.length = lengthUint16
        print("Length: 0x" + String(format: "%02x", self.length) + " - 0d" + String(format: "%u", self.length))
        
        guard let checksum = bits.unpack(bytes: 2) else { return nil }
        let checksumUint16 = checksum.uint16
        self.checksum = checksumUint16
        print("checksum: 0x" + String(format: "%02x", self.checksum))
        DatableConfig.endianess = .little
        
        //payload
        if Int(bits.count/8) > 0
        {
            guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
            
            self.payload = payload
            print("payload:")
            printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
        }
        else
        {
            print("payload: nil")
            self.payload = nil
        }
    }
    
    public var data: Data
    {
        DatableConfig.endianess = .big
        var result = Data()
        
        result.append(sourcePort.data)
        result.append(destinationPort.data)
        result.append(length.data)
        result.append(checksum.data)
        
        if let payloadData = payload
        {
            result.append(payloadData)
        }
        return result
    }
}

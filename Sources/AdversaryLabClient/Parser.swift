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
            
            if ethernetPacket.type == EtherType.IPv4
            {
                if let IPv4Packet = IPv4(data: ethernetPacket.payload)
                {
                    self.ipv4 = IPv4Packet
                    
                    if let payload = IPv4Packet.payload
                    {
                        switch IPv4Packet.protocolNumber
                        {
                        case .TCP:
                            if let TCPsegment = TCP(data: payload)
                            {
                                self.tcp = TCPsegment
                            }
                        case .UDP:
                            if let UDPsegment = UDP(data: payload)
                            {
                                self.udp = UDPsegment
                            }
                        default :
                            return
                        }
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
    case ARP = 0x0806    //Address Resolution Protocol (ARP)
    case IPv6 = 0x86DD    //Internet Protocol Version 6 (IPv6)
    case singleTagVLAN = 0x8100    //VLAN-tagged frame (IEEE 802.1Q)
    case doubleTagVLAN = 0x88A8 //VLAN-tagged (IEEE 802.1Q) frame with double tagging
    //case otherDoubleTagVLAN = 0x9100 //old tag
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
    
    public let version: Bits //UInt8 //4 bits
    public let IHL: Bits //UInt8 //4 bits
    public let DSCP: Bits //UInt8 //6 bits
    public let ECN: Bits //UInt8 //2 bits
    public let length: UInt16 //2 bytes   --number
    public let identification: UInt16 //2 bytes
    public let reservedBit: Bool //UInt8 //1 bit //bool
    public let dontFragment: Bool //UInt8 //1 bit //bool
    public let moreFragments: Bool //UInt8 //1 bit //bool
    public let fragmentOffset: Bits //UInt16 //13 bits   --number
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
    public let version: Bits //UInt8 //4 bits
    public let trafficClass: Bits //UInt8 //8 bits
    public let flowLabel: Bits //UInt32//20bits
    
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
    public let sourcePort: UInt16 //2 bytes
    public let destinationPort: UInt16 //2 bytes
    public let sequenceNumber: Data //4 bytes
    public let acknowledgementNumber: Data //4 bytes
    public let offset: Bits //4 bits
    public let reserved: Bits //3 bits
    public let ns: Bool //1 bit
    public let cwr: Bool //1 bit
    public let ece: Bool //1 bit
    public let urg: Bool //1 bit
    public let ack: Bool //1 bit
    public let psh: Bool //1 bit
    public let rst: Bool //1 bit
    public let syn: Bool //1 bit
    public let fin: Bool //1 bit
    public let windowSize: UInt16 //2 bytes
    public let checksum: UInt16 //2 bytes
    public let urgentPointer: UInt16 //2 bytes
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
        print("Start parsing Ethernet")
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
        // https://en.wikipedia.org/wiki/IEEE_802.1ad
        guard let typeOrTagPrefix = bits.unpack(bytes: 2) else { return nil }
        print("typeOrTagPrefix: 0x", terminator: "")
        printDataBytes(bytes: typeOrTagPrefix, hexDumpFormat: false, seperator: "", decimal: false)
        
        DatableConfig.endianess = .big
        let typeOrTagUInt16 = typeOrTagPrefix.uint16
        print("typeOrTagPrefix: 0xd\(typeOrTagUInt16)")
        
        guard let tempType = EtherType(data: typeOrTagUInt16.data) else {
            print("This EtherType is not known to parser")
            return nil
        }
        
        switch tempType
        {
            //fix, add cases for other ethertypes
            case .IPv4:
                guard let tempType = EtherType(data: typeOrTagPrefix) else { return nil }
                self.tag1 = nil
                self.tag2 = nil
                self.type = tempType
            
            case .singleTagVLAN:
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
                
            default:
                print("This EtherType is not currently handled: \(tempType)")
                return nil
        }
        
        
        if let tag1 = self.tag1
        {
            print("Tag1: 0x", terminator: "")
            printDataBytes(bytes: tag1, hexDumpFormat: false, seperator: "", decimal: false)
        }
        else
        {
            print("Tag1: nil")
        }
        
        if let tag2 = self.tag2
        {
            print("Tag2: 0x", terminator: "")
            printDataBytes(bytes: tag2, hexDumpFormat: false, seperator: "", decimal: false)
        }
        else
        {
            print("Tag2: nil")
        }
        print("EtherType: \(self.type)")
        
        
        guard let payload = bits.unpack(bytes: Int(bits.count/8)) else { return nil }
        self.payload = payload
        print("Ethernet payload:")
        printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
        print("")
        
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
        self.version = version //Uint8
        print("Version: 0x" + String(format: "%02x", versionUint8))
        
        guard let IHL = VerIHLbits.unpack(bits: 4) else { return nil }
        guard let IHLUint8 = IHL.uint8 else { return nil }
        self.IHL = IHL //Uint8
        print("IHL: 0x" + String(format: "%02x", IHLUint8))
        
        guard let DSCPECN = bits.unpack(bytes: 1) else { return nil }
        var DSCPECNbits = Bits(data: DSCPECN)
        guard let DSCP = DSCPECNbits.unpack(bits: 6) else { return nil }
        guard let DSCPUint8 = DSCP.uint8 else { return nil }
        self.DSCP = DSCP //Uint8
        print("DSCP: 0x" + String(format: "%02x", DSCPUint8))
        
        guard let ECN = DSCPECNbits.unpack(bits: 2) else { return nil }
        guard let ECNUint8 = ECN.uint8 else { return nil }
        self.ECN = ECN //Uint8
        print("ECN: 0x" + String(format: "%02x", ECNUint8))
        
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
        
        guard let reservedBit = flagsFragmentOffsetbits.unpackBool() else { return nil }
        guard let dontFragment = flagsFragmentOffsetbits.unpackBool() else { return nil }
        guard let moreFragments = flagsFragmentOffsetbits.unpackBool() else { return nil }
        
        self.reservedBit = reservedBit
        self.dontFragment = dontFragment
        self.moreFragments = moreFragments
        
        print("reservedBit: " + String(self.reservedBit) )
        print("dontFragment: " + String(self.dontFragment) )
        print("moreFragments: " + String(self.moreFragments) )
        
        guard let fragmentOffset = flagsFragmentOffsetbits.unpack(bits: 13) else { return nil }
        guard let fragmentOffsetUint16 = fragmentOffset.uint16 else { return nil }
        self.fragmentOffset = fragmentOffset //Uint16
        print("FragmentOffset: 0d" + String(format: "%u", fragmentOffsetUint16))
        
        guard let ttl = bits.unpack(bytes: 1) else { return nil }
        let ttlUint8 = ttl.uint8
        self.ttl = ttlUint8
        print("TTL: 0d" + String(format: "%u", self.ttl))
        
        guard let protocolNumber = bits.unpack(bytes: 1) else { return nil } //fix should use IPprotocolNumber()
        let protocolNumberUint8 = protocolNumber.uint8
        guard let protocolNumType = IPprotocolNumber(data: protocolNumber) else { return nil }
        self.protocolNumber = protocolNumType
        print("ProtocolNumber: 0d" + String(format: "%u", protocolNumberUint8 ) + " - \(protocolNumType)")
        
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
        print("IPv4 payload:")
        printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
        print("")
        
    }
    
    public var data: Data
    {
        DatableConfig.endianess = .big
        var result = Data()
        
        var verIHLDSCPECN: Bits = Bits()
        let _ = verIHLDSCPECN.pack(bits: version) //4bits
        let _ = verIHLDSCPECN.pack(bits: IHL) //4bits
        let _ = verIHLDSCPECN.pack(bits: DSCP) //6bits
        let _ = verIHLDSCPECN.pack(bits: ECN) //2bits
        result.append(verIHLDSCPECN.data)
        
        result.append(length.data)
        result.append(identification.data)
        
        var flagsFragOff: Bits = Bits()
        let _ = flagsFragOff.pack(bool: reservedBit) //1 bit
        let _ = flagsFragOff.pack(bool: dontFragment) //1 bit
        let _ = flagsFragOff.pack(bool: moreFragments) //1 bit
        let _ = flagsFragOff.pack(bits: fragmentOffset) //13 bits
        result.append(flagsFragOff.data)
        
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
        self.offset = offset
        print("Offset: 0x" + String(format: "%02x", offsetUint8) + " - 0b" + String(offsetUint8, radix: 2))
        
        guard let reserved = dataReservedFlagsBits.unpack(bits: 3) else { return nil }
        guard let reservedUint8 = reserved.uint8 else { return nil }
        self.reserved = reserved
        print("reserved: 0x" + String(format: "%02x", reservedUint8) + " - 0b" + String(reservedUint8, radix: 2))
        
        guard let ns = dataReservedFlagsBits.unpackBool() else { return nil }
        self.ns = ns
        print("ns: " + String(ns) )
        
        guard let cwr = dataReservedFlagsBits.unpackBool() else { return nil }
        self.cwr = cwr
        print("cwr: " + String(self.cwr))
        
        guard let ece = dataReservedFlagsBits.unpackBool() else { return nil }
        self.ece = ece
        print("ece: " + String(self.ece))
        
        guard let urg = dataReservedFlagsBits.unpackBool() else { return nil }
        self.urg = urg
        print("urg: " + String(self.urg))
        
        guard let ack = dataReservedFlagsBits.unpackBool() else { return nil }
        self.ack = ack
        print("ack: " + String(self.ack))
        
        guard let psh = dataReservedFlagsBits.unpackBool() else { return nil }
        self.psh = psh
        print("psh: " + String(self.psh))
        
        guard let rst = dataReservedFlagsBits.unpackBool() else { return nil }
        self.rst = rst
        print("rst: " + String(self.rst))
        
        guard let syn = dataReservedFlagsBits.unpackBool() else { return nil }
        self.syn = syn
        print("syn: " + String(self.syn))
        
        guard let fin = dataReservedFlagsBits.unpackBool() else { return nil }
        self.fin = fin
        print("fin: " + String(self.fin))
        
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
            let bytesToRead = Int((offsetUint8 - 5) * 4)
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
            print("TCP payload:")
            printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
            print("")
        }
        else
        {
            print("TCP payload: nil\n")
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
        
        var offsetReservedFlags: Bits = Bits()
        let _ = offsetReservedFlags.pack(bits: offset)
        let _ = offsetReservedFlags.pack(bits: reserved)
        let _ = offsetReservedFlags.pack(bool: ns)
        let _ = offsetReservedFlags.pack(bool: cwr)
        let _ = offsetReservedFlags.pack(bool: ece)
        let _ = offsetReservedFlags.pack(bool: urg)
        let _ = offsetReservedFlags.pack(bool: ack)
        let _ = offsetReservedFlags.pack(bool: psh)
        let _ = offsetReservedFlags.pack(bool: rst)
        let _ = offsetReservedFlags.pack(bool: syn)
        let _ = offsetReservedFlags.pack(bool: fin)
        result.append(offsetReservedFlags.data)
        
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
        print("start parsing UDP")
        DatableConfig.endianess = .little
        var bits = Bits(data: data)
        
        DatableConfig.endianess = .big
        guard let sourcePort = bits.unpack(bytes: 2) else { return nil }
        let sourcePortUint16 = sourcePort.uint16
        self.sourcePort = sourcePortUint16
        print("UDPsourcePort: 0x" + String(format: "%02x", self.sourcePort) + " - 0d" + String(format: "%u", self.sourcePort))
        
        guard let destinationPort = bits.unpack(bytes: 2) else { return nil }
        let destinationPortUint16 = destinationPort.uint16
        self.destinationPort = destinationPortUint16
        print("UDPdestinationPort: 0x" + String(format: "%02x", self.destinationPort) + " - 0d" + String(format: "%u", self.destinationPort))
        
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
            print("UDP payload:")
            printDataBytes(bytes: payload, hexDumpFormat: true, seperator: "", decimal: false)
            print("")
            
        }
        else
        {
            print("UDP payload: nil\n")
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

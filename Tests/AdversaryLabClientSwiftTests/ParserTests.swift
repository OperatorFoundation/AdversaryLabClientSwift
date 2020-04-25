//
//  ParserTests.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/2/20.
//

import Foundation
import XCTest
import Datable
@testable import AdversaryLabClient

final class ParserTests: XCTestCase
{
    func testDatable_endianness1()
    {
        DatableConfig.endianess = .little
        
        let correct = Int(0x08)
        
        let data = Data(array: [0x08])
        
        let result = data.int
        
        XCTAssertEqual(correct, result)
    }

    func testDatable_endianness2()
    {
        DatableConfig.endianess = .little

        let correct: Int = 0x08
        
        let data = Data(array: [0x08])
        
        let result = data.int
        
        XCTAssertEqual(correct, result)
    }
    
    func testDatable_endianness4()
    {
        DatableConfig.endianess = .big

        let correct: UInt16 = 0x0800
        
        let data = Data(array: [0x08, 0x00])
        
        let result = data.uint16
        
        XCTAssertEqual(correct, result)
    }

    func testDatable_endianness5()
    {
        DatableConfig.endianess = .big

        let correct: Int = 0x0800
        
        let data = Data(array: [0x08, 0x00])
        
        let result = Int(data.uint16)
        
        XCTAssertEqual(correct, result)
    }
    
    // Test Ethertype parser
    func testEthertype_0x0800()
    {
        DatableConfig.endianess = .big
        
        let correct = EtherType(rawValue: 0x0800)
        
        let data = Data(array: [0x08, 0x00])
        
        guard let result = EtherType(data: data) else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(correct, result)
    }
    
    func testEthertype_Data_getter(){
        //fix / verify
        let correct = Data(array: [0x08, 0x00])
        let ET = EtherType(rawValue: 0x0800)
        let result = ET?.data
        
        XCTAssertEqual(correct, result)
    }
    
    
    func testIPVersionInit(){
        //fix /verify
        var bits = Bits()
        let correct = IPversion(rawValue: 0x04)
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        let result = IPversion(bits: bits)
        
        XCTAssertEqual(correct, result)
        
    }
    
    func testIPVersionBits(){
        //fix /verify
        var correct = Bits()
        
        guard correct.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard correct.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard correct.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        let ipv = IPversion(rawValue: 0x04)
        let result = ipv?.bits?.uint
        
        XCTAssertEqual(correct.uint, result)
    }
    
    func testEthernetInit(){
        //fix / verify
        //sample source: https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=get&target=tcp-ethereal-file1.trace
        //packet #4
        let packetBytes = Data(array: [
         0x00, 0x05, 0x9a, 0x3c, 0x78, 0x00, 0x00, 0x0d, 0x88, 0x40, 0xdf, 0x1d, 0x08, 0x00, 0x45, 0x00,
         0x00, 0x30, 0x00, 0x00, 0x40, 0x00, 0x34, 0x06, 0x2d, 0xc9, 0x80, 0x77, 0xf5, 0x0c, 0x83, 0xd4,
         0x1f, 0xa7, 0x00, 0x50, 0x08, 0x30, 0x3d, 0xe4, 0xa9, 0x33, 0x99, 0x5f, 0xcf, 0x79, 0x70, 0x12,
         0x05, 0xb4, 0x0b, 0xeb, 0x00, 0x00, 0x02, 0x04, 0x05, 0xb4, 0x01, 0x01, 0x04, 0x02])
        
        let correctMACsource = Data(array: [0x00, 0x0d, 0x88, 0x40, 0xdf, 0x1d])
        let correctMACdestination = Data(array: [0x00, 0x05, 0x9a, 0x3c, 0x78, 0x00])
        let correctType = EtherType(rawValue: 0x0800) //IPv4
        //let correctTag1 = Data(array: [])
        //let correctTag2 = Data(array: [])
        let correctPayload = Data(array: [
            0x45, 0x00, 0x00, 0x30, 0x00, 0x00, 0x40, 0x00,
            0x34, 0x06, 0x2d, 0xc9, 0x80, 0x77, 0xf5, 0x0c,
            0x83, 0xd4, 0x1f, 0xa7, 0x00, 0x50, 0x08, 0x30,
            0x3d, 0xe4, 0xa9, 0x33, 0x99, 0x5f, 0xcf, 0x79,
            0x70, 0x12, 0x05, 0xb4, 0x0b, 0xeb, 0x00, 0x00,
            0x02, 0x04, 0x05, 0xb4, 0x01, 0x01, 0x04, 0x02])
        
        let correctIPv4version: UInt8 = 0x04
        let correctIPv4IHL: UInt8 = 0x05
        let correctIPv4DSCP: UInt8 = 0x00
        let correctIPv4ECN: UInt8 = 0x00 //(48)
        let correctIPv4length: UInt16 = 0x0030
        let correctIPv4identification: UInt16 = 0x0000
        //let correctIPv4flags: UInt8 = 0b010 //UInt8 3 bits
        let correctIPv4reservedBit: UInt8 = 0b0
        let correctIPv4dontFragment: UInt8 = 0b1
        let correctIPv4moreFragments: UInt8 = 0b0
        let correctIPv4fragmentOffset: UInt16 = 0x0000
        let correctIPv4ttl: UInt8 = 0x34 //(52)
        let correctIPv4protocolNumber: UInt8 = 0x06 //tcp
        let correctIPv4checksum: UInt16 = 0x2dc9
        let correctIPv4sourceAddress: Data = Data(array:[0x80, 0x77, 0xf5, 0x0c]) //128.119.245.12
        let correctIPv4destinationAddress: Data = Data(array:[0x83, 0xd4, 0x1f, 0xa7]) //131.212.31.167
        let correctIPv4options: Data? = nil
        let correctIPv4payload: Data = Data(array:[
            0x00, 0x50, 0x08, 0x30, 0x3d, 0xe4, 0xa9, 0x33,
            0x99, 0x5f, 0xcf, 0x79, 0x70, 0x12, 0x05, 0xb4,
            0x0b, 0xeb, 0x00, 0x00, 0x02, 0x04, 0x05, 0xb4,
            0x01, 0x01, 0x04, 0x02])
        
        let correctIPV4data: Data = Data(array:[
            //fix, why do bytes need to be reversed, is this ok? do we just assume .little?
            0x04, //ver
            0x05, //ihl
            0x00, //dscp
            0x00, //ecn
            0x30, 0x00, //length -- reversed bytes due to endianess
            0x00, 0x00, //identification -- reversed bytes due to endianess
            0x00, //reserved bit
            0x01, //don't fragment
            0x00, //morefragments
            0x00, 0x00, //fragment offset -- reversed bytes due to endianess
            0x34, //ttl
            0x06, //protocol number
            0xc9, 0x2d, //checksum -- reversed bytes due to endianess
            0x80, 0x77, 0xf5, 0x0c, //source address
            0x83, 0xd4, 0x1f, 0xa7, //destination address
            //no options
            //payload
            0x00, 0x50, 0x08, 0x30, 0x3d, 0xe4, 0xa9, 0x33,
            0x99, 0x5f, 0xcf, 0x79, 0x70, 0x12, 0x05, 0xb4,
            0x0b, 0xeb, 0x00, 0x00, 0x02, 0x04, 0x05, 0xb4,
            0x01, 0x01, 0x04, 0x02
        ])
        

        
        if let epacket = Ethernet(data: packetBytes){
            
            XCTAssertEqual(epacket.MACDestination, correctMACdestination)
            XCTAssertEqual(epacket.MACSource, correctMACsource)
            XCTAssertEqual(epacket.type, correctType)
            XCTAssertEqual(epacket.payload, correctPayload)
            XCTAssertNil(epacket.tag1)
            XCTAssertNil(epacket.tag2)
            
            let epacketData = epacket.data
            XCTAssertEqual(epacketData, packetBytes)
            
            
            if let IPv4part = IPv4(data: epacket.payload){
                XCTAssertEqual(IPv4part.version, correctIPv4version)
                XCTAssertEqual(IPv4part.IHL, correctIPv4IHL)
                XCTAssertEqual(IPv4part.DSCP, correctIPv4DSCP)
                XCTAssertEqual(IPv4part.ECN, correctIPv4ECN)
                XCTAssertEqual(IPv4part.length, correctIPv4length)
                XCTAssertEqual(IPv4part.identification, correctIPv4identification)
                XCTAssertEqual(IPv4part.reservedBit, correctIPv4reservedBit)
                XCTAssertEqual(IPv4part.dontFragment, correctIPv4dontFragment)
                XCTAssertEqual(IPv4part.moreFragments, correctIPv4moreFragments)
                XCTAssertEqual(IPv4part.fragmentOffset, correctIPv4fragmentOffset)
                XCTAssertEqual(IPv4part.ttl, correctIPv4ttl)
                XCTAssertEqual(IPv4part.protocolNumber, correctIPv4protocolNumber)
                XCTAssertEqual(IPv4part.checksum, correctIPv4checksum)
                XCTAssertEqual(IPv4part.sourceAddress, correctIPv4sourceAddress)
                XCTAssertEqual(IPv4part.destinationAddress, correctIPv4destinationAddress)
                XCTAssertEqual(IPv4part.options, correctIPv4options)
                XCTAssertEqual(IPv4part.payload, correctIPv4payload)
                
                let IPV4partData = IPv4part.data
                XCTAssertEqual(IPV4partData, correctIPV4data)
                
                
                
            }else {
                XCTFail()
                return
            }
            
        } else {
            XCTFail()
            return
        }
        
    }
    
    func testEthernetInit_VLANtag(){
        //https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=get&target=vlan.cap.gz
        //packet #6
        let packetVLANBytes = Data(array: [
            0x00, 0x40, 0x05, 0x40, 0xef, 0x24, 0x00, 0x60, 0x08, 0x9f, 0xb1, 0xf3, 0x81, 0x00, 0x00, 0x20,
            0x08, 0x00, 0x45, 0x00, 0x00, 0x34, 0x8a, 0x1b, 0x40, 0x00, 0x40, 0x06, 0x68, 0xe4, 0x83, 0x97,
            0x20, 0x15, 0x83, 0x97, 0x20, 0x81, 0x17, 0x70, 0x04, 0x8a, 0x4d, 0x3d, 0x54, 0xb9, 0x4e, 0x14,
            0xde, 0x3d, 0x80, 0x10, 0x7c, 0x70, 0x31, 0xed, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a, 0x01, 0x99,
            0xa3, 0xf3, 0x00, 0x04, 0xf0, 0xc7
        ])
        
        let correctMACdestination = Data(array: [0x00, 0x40, 0x05, 0x40, 0xef, 0x24])
        let correctMACsource = Data(array: [0x00, 0x60, 0x08, 0x9f, 0xb1, 0xf3])
        let correctType = EtherType(rawValue: 0x0800) //IPv4
        let correctTag1 = Data(array: [0x81, 0x00, 0x00, 0x20])
        //let correctTag2 = Data(array: [])
        let correctPayload = Data(array: [
            0x45, 0x00, 0x00, 0x34, 0x8a, 0x1b, 0x40, 0x00, 0x40, 0x06, 0x68, 0xe4, 0x83, 0x97,
            0x20, 0x15, 0x83, 0x97, 0x20, 0x81, 0x17, 0x70, 0x04, 0x8a, 0x4d, 0x3d, 0x54, 0xb9, 0x4e, 0x14,
            0xde, 0x3d, 0x80, 0x10, 0x7c, 0x70, 0x31, 0xed, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a, 0x01, 0x99,
            0xa3, 0xf3, 0x00, 0x04, 0xf0, 0xc7
        ])
        
        
        
        if let epacket = Ethernet(data: packetVLANBytes){
            XCTAssertEqual(epacket.MACDestination, correctMACdestination)
            XCTAssertEqual(epacket.MACSource, correctMACsource)
            XCTAssertEqual(epacket.type, correctType)
            XCTAssertEqual(epacket.payload, correctPayload)
            XCTAssertEqual(epacket.tag1, correctTag1)
            XCTAssertNil(epacket.tag2)
        }
        
        
        
        
        
    }
    
    func testEthernetInit_VLANdoubleTag(){
        //https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=get&target=hp-erm-2.cap
        //fix / verify
    }
    
    func testUDPInit(){
        //https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=get&target=b6300a.cap
        //packet #2
        
        let packetUDPBytes = Data(array: [
            0x00, 0xa1, 0x3e, 0x2c, 0x00, 0x42, 0x7d, 0x6d, 0x30, 0x38, 0x02, 0x01, 0x00, 0x04, 0x06, 0x70,
            0x75, 0x62, 0x6c, 0x69, 0x63, 0xa2, 0x2b, 0x02, 0x01, 0x26, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00,
            0x30, 0x20, 0x30, 0x1e, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x02, 0x01, 0x01, 0x02, 0x00, 0x06, 0x12,
            0x2b, 0x06, 0x01, 0x04, 0x01, 0x8f, 0x51, 0x01, 0x01, 0x01, 0x82, 0x29, 0x5d, 0x01, 0x1b, 0x02,
            0x02, 0x01
        ])
        
        let correctSourcePort: UInt16 = 0x00a1
        let correctDestinationPort: UInt16 = 0x3e2c
        let correctLength: UInt16 = 0x0042
        let correctChecksum: UInt16 = 0x7d6d
        let correctPayload: Data = Data(array:[
            0x30, 0x38, 0x02, 0x01, 0x00, 0x04, 0x06, 0x70, 0x75, 0x62, 0x6c, 0x69, 0x63, 0xa2, 0x2b, 0x02,
            0x01, 0x26, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00, 0x30, 0x20, 0x30, 0x1e, 0x06, 0x08, 0x2b, 0x06,
            0x01, 0x02, 0x01, 0x01, 0x02, 0x00, 0x06, 0x12, 0x2b, 0x06, 0x01, 0x04, 0x01, 0x8f, 0x51, 0x01,
            0x01, 0x01, 0x82, 0x29, 0x5d, 0x01, 0x1b, 0x02, 0x02, 0x01
        ])
        
        if let udpSegment = UDP(data: packetUDPBytes){
            XCTAssertEqual(udpSegment.sourcePort, correctSourcePort)
            XCTAssertEqual(udpSegment.destinationPort, correctDestinationPort)
            XCTAssertEqual(udpSegment.length, correctLength)
            XCTAssertEqual(udpSegment.checksum, correctChecksum)
            XCTAssertEqual(udpSegment.payload, correctPayload)
            
            
        } else {
            XCTFail()
            return
        }
        
    }
    
    func testUDPInitFails(){
        //https://wiki.wireshark.org/SampleCaptures?action=AttachFile&do=get&target=b6300a.cap
        //packet #2
        
        //let packetUDPBytes = Data(array: [
        //0x00, 0xa1, 0x3e, 0x2c, 0x00, 0x42, 0x7d, 0x6d, 0x30, 0x38, 0x02, 0x01, 0x00, 0x04, 0x06, 0x70,
        //0x75, 0x62, 0x6c, 0x69, 0x63, 0xa2, 0x2b, 0x02, 0x01, 0x26, 0x02, 0x01, 0x00, 0x02, 0x01, 0x00,
        //0x30, 0x20, 0x30, 0x1e, 0x06, 0x08, 0x2b, 0x06, 0x01, 0x02, 0x01, 0x01, 0x02, 0x00, 0x06, 0x12,
        //0x2b, 0x06, 0x01, 0x04, 0x01, 0x8f, 0x51, 0x01, 0x01, 0x01, 0x82, 0x29, 0x5d, 0x01, 0x1b, 0x02,
        //0x02, 0x01
        //])
        
        let packetUDPBytesSourcePortFail = Data(array: [0x00])
        let packetUDPBytesDestinationFail = Data(array: [0x00, 0xa1, 0x3e])
        let packetUDPBytesLengthFail = Data(array: [0x00, 0xa1, 0x3e, 0x2c, 0x00])
        let packetUDPBytesChecksumFail = Data(array: [0x00, 0xa1, 0x3e, 0x2c, 0x00, 0x42, 0x7d])
        let packetUDPBytesPayloadFail = Data(array: [0x00, 0xa1, 0x3e, 0x2c, 0x00, 0x42, 0x7d, 0x6d])
        
        XCTAssertNil(UDP(data: packetUDPBytesSourcePortFail))
        XCTAssertNil(UDP(data: packetUDPBytesDestinationFail))
        XCTAssertNil(UDP(data: packetUDPBytesLengthFail))
        XCTAssertNil(UDP(data: packetUDPBytesChecksumFail))
        XCTAssertNil(UDP(data: packetUDPBytesPayloadFail)!.payload)
        
    }
    
    func testIPprotocolNumber_init(){
        
        if let ICMPtest = IPprotocolNumber(data: Data(array: [0x01])){
            XCTAssertEqual(ICMPtest, .ICMP)
        } else {
                   XCTFail()
                   return
        }
    }
    
    func testIPprotocolNumber_data(){
        let ICMPcorrect = Data(array: [0x01])
        let ICMP = IPprotocolNumber.ICMP
        
        if let ICMPtest = ICMP.data {
            
            XCTAssertEqual(ICMPtest, ICMPcorrect)
        } else {
                   XCTFail()
                   return
        }

    }

    
    
    
}

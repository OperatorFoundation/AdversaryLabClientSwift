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
    
    func testDatable_endianness3()
    {
        DatableConfig.endianess = .little

        let correct: Int = 0x0800
        
        let data = Data(array: [0x08, 0x00])
        
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
}

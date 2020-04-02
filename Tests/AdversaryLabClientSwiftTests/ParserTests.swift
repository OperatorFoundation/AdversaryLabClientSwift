//
//  ParserTests.swift
//  
//
//  Created by Dr. Brandon Wiley on 4/2/20.
//

import Foundation
import XCTest
@testable import AdversaryLabClient

final class ParserTests: XCTestCase
{
    // SimpleBits tests
    func testEthertype_0x0800()
    {
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

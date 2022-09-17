//
//  File.swift
//  
//
//  Created by Mafalda on 9/15/22.
//

import Foundation

import XCTest

@testable import AdversaryLabClientCore

class AdversaryLabClientCoreTests: XCTestCase
{
    func testTimestamps()
    {
        let now = Date()
        let timestamp = Int(now.timeIntervalSince1970 * 1000000)
        
        print("Now: \(now)")
        print("Timestamp: \(timestamp)")
    }
}

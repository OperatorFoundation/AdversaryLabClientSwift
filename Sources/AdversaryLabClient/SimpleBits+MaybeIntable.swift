//
//  SimpleBits+MaybeIntable.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/27/20.
//

import Foundation
import Datable

extension SimpleBits: MaybeIntable
{
    public init?(int: Int) {
        if int < 0 || int > UINT8_MAX
        {
            return nil
        }
        
        let ui8 = UInt8(int)
        self.init(data: Data(array: [ui8]))
    }
    
    public var int: Int? {
        guard let int8 = self.int8 else
        {
            return nil
        }
        
        return Int(int8)
    }
    
    public init?(int8: Int8) {
        if int8 < 0 || int8 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(int8)
        self.init(data: Data(array: [ui8]))
    }
    
    public var int8: Int8? {
        // Negative number
        if count == 8 && get(index: 0) == 1
        {
            guard let uint8 = self.uint8 else
            {
                return nil
            }
            
            let dropSign = (uint8 << 1) >> 1
            let int8 = Int8(dropSign)
            return -int8
        }
        else // Non-negative number
        {
            guard let uint8 = self.uint8 else
            {
                return nil
            }
            
            return Int8(uint8)
        }
    }
    
    public init?(int16: Int16) {
        if int16 < 0 || int16 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(int16)
        self.init(data: Data(array: [ui8]))
    }
    
    public var int16: Int16? {
        guard let int8 = self.int8 else
        {
            return nil
        }
        
        return Int16(int8)
    }
    
    public init?(int32: Int32) {
        if int32 < 0 || int32 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(int32)
        self.init(data: Data(array: [ui8]))
    }
    
    public var int32: Int32? {
        guard let int8 = self.int8 else
        {
            return nil
        }
        
        return Int32(int8)
    }
    
    public init?(int64: Int64) {
        if int64 < 0 || int64 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(int64)
        self.init(data: Data(array: [ui8]))

    }
    
    public var int64: Int64? {
        guard let int8 = self.int8 else
        {
            return nil
        }
        
        return Int64(int8)
    }
    
    public init?(uint: UInt) {
        if uint < 0 || uint > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(uint)
        self.init(data: Data(array: [ui8]))
    }
    
    public var uint: UInt? {
        guard let uint8 = self.uint8 else
        {
            return nil
        }
        
        return UInt(uint8)
    }
    
    public init?(uint8: UInt8) {
        self.init(data: Data(array: [uint8]))
    }
    
    public var uint8: UInt8? {
        let offset = UInt8.bitWidth - count
        return UInt8(buffer) >> offset
    }
    
    public init?(uint16: UInt16) {
        if uint16 < 0 || uint16 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(uint16)
        self.init(data: Data(array: [ui8]))
    }
    
    public var uint16: UInt16? {
        guard let uint8 = self.uint8 else
        {
            return nil
        }
        
        return UInt16(uint8)
    }
    
    public init?(uint32: UInt32) {
        if uint32 < 0 || uint32 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(uint32)
        self.init(data: Data(array: [ui8]))
    }
    
    public var uint32: UInt32? {
        guard let uint8 = self.uint8 else
        {
            return nil
        }
        
        return UInt32(uint8)
    }
    
    public init?(uint64: UInt64) {
        if uint64 < 0 || uint64 > UINT8_MAX
        {
            return nil
        }

        let ui8 = UInt8(uint64)
        self.init(data: Data(array: [ui8]))
    }
    
    public var uint64: UInt64? {
        guard let uint8 = self.uint8 else
        {
            return nil
        }
        
        return UInt64(uint8)
    }
}

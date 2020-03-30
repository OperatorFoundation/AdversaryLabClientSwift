//
//  Bits+MaybeIntable.swift
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
        return Int(buffer)
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
        return Int8(buffer)
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
        return Int16(buffer)
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
        return Int32(buffer)
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
        return Int64(buffer)
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
        return UInt(buffer)
    }
    
    public init?(uint8: UInt8) {
        self.init(data: Data(array: [uint8]))
    }
    
    public var uint8: UInt8? {
        return UInt8(buffer)
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
        return UInt16(buffer)
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
        return UInt32(buffer)
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
        return UInt64(buffer)
    }
}

extension Bits: MaybeIntable
{
    public init?(int: Int) {
        self.init(data: int.data)
    }
    
    public var int: Int? {
        if count > Int.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return Int(data: data)
        }
        else
        {
            let data = buffer
            return Int(data: data)
        }
    }
    
    public init?(int8: Int8) {
        self.init(data: int8.data)
    }
    
    public var int8: Int8? {
        if count > Int8.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return Int8(data: data)
        }
        else
        {
            let data = buffer
            return Int8(data: data)
        }

    }
    
    public init?(int16: Int16) {
        self.init(data: int16.data)
    }
    
    public var int16: Int16? {
        if count > Int16.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return Int16(data: data)
        }
        else
        {
            let data = buffer
            return Int16(data: data)
        }

    }
    
    public init?(int32: Int32) {
        self.init(data: int32.data)
    }
    
    public var int32: Int32? {
        if count > Int32.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return Int32(data: data)
        }
        else
        {
            let data = buffer
            return Int32(data: data)
        }
    }
    
    public init?(int64: Int64) {
        self.init(data: int64.data)
    }
    
    public var int64: Int64? {
        if count > Int64.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return Int64(data: data)
        }
        else
        {
            let data = buffer
            return Int64(data: data)
        }
    }
    
    public init?(uint: UInt) {
        self.init(data: uint.data)
    }
    
    public var uint: UInt? {
        if count > UInt.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return UInt(data: data)
        }
        else
        {
            let data = buffer
            return UInt(data: data)
        }

    }
    
    public init?(uint8: UInt8) {
        self.init(data: uint8.data)
    }
    
    public var uint8: UInt8? {
        if count > UInt8.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return UInt8(data: data)
        }
        else
        {
            let data = buffer
            return UInt8(data: data)
        }
    }
    
    public init?(uint16: UInt16) {
        self.init(data: uint16.data)
    }
    
    public var uint16: UInt16? {
        if count > UInt16.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return UInt16(data: data)
        }
        else
        {
            let data = buffer
            return UInt16(data: data)
        }

    }
    
    public init?(uint32: UInt32) {
        self.init(data: uint32.data)
    }
    
    public var uint32: UInt32? {
        if count > UInt32.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return UInt32(data: data)
        }
        else
        {
            let data = buffer
            return UInt32(data: data)
        }

    }
    
    public init?(uint64: UInt64) {
        self.init(data: uint64.data)
    }
    
    public var uint64: UInt64? {
        if count > UInt64.bitWidth
        {
            return nil
        }
        
        if let extra = leftover
        {
            let data = buffer + extra.data
            return UInt64(data: data)
        }
        else
        {
            let data = buffer
            return UInt64(data: data)
        }
    }
}

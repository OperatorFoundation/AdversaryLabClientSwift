//
//  Bits.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/10/20.
//

import Foundation
import Datable

public struct SimpleBits: MaybeDatable
{
    var buffer: UInt8
    var count: Int
    var byteAligned: Bool

    public init()
    {
        buffer = 0
        count = 0
        byteAligned = false
    }
    
    public init?(data: Data)
    {
        guard data.count == 1 else
        {
            return nil
        }
        
        buffer = data[0]
        count = 8
        byteAligned = true
    }
 
    public var data: Data
    {
        get
        {
            if byteAligned
            {
                return Data(array: [buffer])
            }
            else
            {
                return Data()
            }
        }
    }
    
    public mutating func pack(bit: UInt8) -> Bool
    {
        guard count < 8 else
        {
            return false
        }

        // Push bit to right-most index
        if set(bit: bit, index: count)
        {
            count += 1
            byteAligned = count == 8
            return true
        }
        else
        {
            return false
        }
    }

    public mutating func pack(bits: SimpleBits) -> Bool
    {
        var mbits = bits
        
        if count + mbits.count > 8
        {
            return false
        }
        
        for _ in 0..<mbits.count
        {
            guard let bit = mbits.unpackBit() else
            {
                return false
            }
            
            if !pack(bit: bit)
            {
                return false
            }
        }
        
        return true
    }
    
    public mutating func unpackBit() -> UInt8?
    {
        // Read bit at left-most index
        guard let result = get(index: 0) else
        {
            return nil
        }

        // Pop bit at left-most index
        buffer = buffer << 1
        count -= 1
        byteAligned = false
        
        return result
    }

    public mutating func unpack(bits: Int) -> SimpleBits?
    {
        if bits > count
        {
            return nil
        }

        var result = SimpleBits()
        
        for _ in 0..<bits
        {
            print(index)
            guard let bit = unpackBit() else
            {
                return nil
            }
            
            if !result.pack(bit: bit)
            {
                return nil
            }
        }
        
        return result
    }
    
    mutating func set(bit: UInt8, index: Int) -> Bool
    {
        if (bit != 0) && (bit != 1)
        {
            return false
        }
        
        guard (index >= 0) && (index < 8) else
        {
            return false
        }

        let offset: UInt8 = UInt8(7) - UInt8(index)
        buffer = buffer | (bit << offset)
        
        return true
    }
    
    func get(index: Int) -> UInt8?
    {
        guard (index >= 0) && (index < count) else
        {
            return nil
        }
        
        let offset: UInt8 = UInt8(7) - UInt8(index)
        return (buffer & (1 << offset)) >> offset
    }
}

public struct Bits: MaybeDatable
{
    var buffer: Data
    var count: Int
    var byteAligned: Bool
    var leftover: SimpleBits?
    
    public init()
    {
        buffer = Data()
        count = 0
        byteAligned = false
    }

    public init(data: Data) {
        buffer = data
        count = buffer.count * 8
        byteAligned = true
    }
    
    public init(data: Data?, bits: SimpleBits?)
    {
        if let bytes = data
        {
            buffer = bytes
            count = bytes.count * 8
            byteAligned = true
            leftover = nil
        }
        else
        {
            buffer = Data()
            count = 0
            byteAligned = true
            leftover = nil
        }

        if let bs = bits
        {
            count += bs.count
            byteAligned = bs.byteAligned
            leftover = bs
        }
    }
    
    public var data: Data
    {
        get
        {
            guard byteAligned else
            {
                return Data()
            }
            
            return buffer
        }
    }
    
    public mutating func pack(bytes: Data) -> Bool
    {
        guard byteAligned else
        {
            return false
        }
        
        buffer.append(bytes)
        count += bytes.count * 8
        return true
    }
    
    public mutating func unpack(bytes: Int) -> Data?
    {
        guard byteAligned else
        {
            return nil
        }
        
        guard let (result, rest) = splitData(buffer, bytes) else
        {
            return nil
        }
        
        buffer = rest
        count -= bytes * 8
        byteAligned = count > 0 && count % 8 == 0
        leftover = nil
        return result
    }
    
    public mutating func pack(bits: Bits)
    {
        
    }
    
    public mutating func unpackBit() -> UInt8?
    {
        guard let result = unpack(bits: 1) else
        {
            return nil
        }
        
        guard result.count == 1 else
        {
            return nil
        }
        
        guard result.buffer.count == 0 else
        {
            return nil
        }
        
        guard var bits = result.leftover else
        {
            return nil
        }
        
        guard bits.count == 1 else
        {
            return nil
        }
        
        return bits.unpackBit()
    }
    
    public mutating func unpack(bits: Int) -> Bits?
    {
        if byteAligned
        {
            if bits % 8 == 0 // This also covers the case where bits == 8
            {
                guard let bytes = unpack(bytes: bits/8) else
                {
                    return nil
                }
                
                return Bits(data: bytes, bits: nil)
            }
            else if bits < 8
            {
                guard let data = unpack(bytes: 1) else
                {
                    return nil
                }
                
                guard let bytebits = SimpleBits(data: data) else
                {
                    return nil
                }

                leftover = bytebits

                guard let result = leftover!.unpack(bits: bits) else
                {
                    return nil
                }
                
                return Bits(data: Data(), bits: result)
            }
            else // bits > 8
            {
                let bytes = bits / 8
                let remainingBits = bits % 8
                
                guard let bytesResult = unpack(bytes: bytes) else
                {
                    return nil
                }
                
                guard let bitsResult = unpack(bits: remainingBits) else
                {
                    return nil
                }
                
                var result = Bits(data: bytesResult)
                result.pack(bits: bitsResult)
                
                return result
            }
        }
        else
        {
            if buffer.count == 0
            {
                guard var bs = leftover else
                {
                    return nil
                }
                
                guard bits <= bs.count else
                {
                    return nil
                }
                
                guard let result = bs.unpack(bits: bits) else
                {
                    return nil
                }
                
                return Bits(data: nil, bits: result)
            }
            else
            {
                // FIXME - write this case
                return nil
            }
        }
    }
}

func splitData(_ data: Data, _ index: Int) -> (Data, Data)?
{
    guard data.count >= index else
    {
        return nil
    }
    
    return (Data(data[..<index]), Data(data[index...]))
}

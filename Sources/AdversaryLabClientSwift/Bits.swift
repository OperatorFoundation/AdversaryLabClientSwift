//
//  Bits.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/10/20.
//

import Foundation
import Datable

struct SimpleBits: MaybeDatable
{
    var buffer: UInt8
    var count: Int
    var byteAligned: Bool

    init()
    {
        buffer = 0
        count = 0
        byteAligned = false
    }
    
    init?(data: Data)
    {
        guard data.count == 1 else
        {
            return nil
        }
        
        buffer = data[0]
        count = 8
        byteAligned = true
    }
 
    var data: Data
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
    
    mutating func pack(bit: UInt8) -> Bool
    {
        guard count < 8 else
        {
            return false
        }

        // Push bit to right-most index
        if set(bit: bit, index: count-1)
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

    mutating func pack(bits: SimpleBits) -> Bool
    {
        var mbits = bits
        
        if count + mbits.count > 8
        {
            return false
        }
        
        for _ in [..<mbits.count]
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
    
    mutating func unpackBit() -> UInt8?
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

    mutating func unpack(bits: Int) -> SimpleBits?
    {
        if bits > 8
        {
            return nil
        }

        var result = SimpleBits()
        
        for _ in [..<bits]
        {
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
        
        if (index < 0) || (index > 7)
        {
            return false
        }
        
        buffer = buffer & (bit << index)
        
        return true
    }
    
    func get(index: Int) -> UInt8?
    {
        if (index < 0) || (index > 7)
        {
            return nil
        }
        
        return buffer | (1 << index)
    }
}

struct Bits: MaybeDatable
{
    var buffer: Data
    var count: Int
    var byteAligned: Bool
    var leftover: SimpleBits?

    init(data: Data) {
        buffer = data
        count = buffer.count * 8
        byteAligned = true
    }
    
    init(data: Data?, bits: SimpleBits?)
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
    
    var data: Data
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
    
    mutating func pack(bytes: Data) -> Bool
    {
        guard byteAligned else
        {
            return false
        }
        
        buffer.append(bytes)
        count += bytes.count * 8
        return true
    }
    
    mutating func unpack(bytes: Int) -> Data?
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
        return result
    }
    
    mutating func pack(bits: Bits)
    {
        
    }
    
    mutating func unpack(bits: Int) -> Bits?
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
            // FIXME - write this case
            return nil
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

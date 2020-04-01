//
//  Bits.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/10/20.
//

import Foundation
import Datable

// SimpleBits is a simplified version of Bits which uses only one byte
public struct SimpleBits: MaybeDatable
{
    var buffer: UInt8
    var count: Int
    
    var byteAligned: Bool
    {
        get
        {
            return count == 8
        }
    }

    public init()
    {
        buffer = 0
        count = 0
    }
    
    public init?(data: Data)
    {
        guard data.count == 1 else
        {
            return nil
        }
        
        buffer = data[0]
        count = 8
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
        let mask = bit << offset
        buffer = buffer | mask
        
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

// Bits allows for packing and unpacking of both bytes and bits in relation to an array of bytes of arbitrary length
public struct Bits: MaybeDatable
{
    var buffer: Data
    var leftover: SimpleBits?
    
    var count: Int
    {
        get
        {
            if let partial = leftover
            {
                return (buffer.count * 8) + partial.count
            }
            else
            {
                return buffer.count * 8
            }
        }
    }
    
    var byteAligned: Bool
    {
        get
        {
            return buffer.count > 0 && leftover == nil
        }
    }

    public init()
    {
        buffer = Data()
    }

    public init(data: Data) {
        buffer = data
    }
    
    public init(data: Data?, bits: SimpleBits?)
    {
        if let bytes = data
        {
            buffer = bytes
            leftover = nil
        }
        else
        {
            buffer = Data()
            leftover = nil
        }

        if let bs = bits
        {
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
        leftover = nil
        return result
    }

    public mutating func pack(bit: UInt8) -> Bool
    {
        var simple = SimpleBits()
        guard simple.pack(bit: bit) else {return false}
        
        let bits = Bits(data: nil, bits: simple)
        return pack(bits: bits)
    }
    
    public mutating func pack(bits: Bits) -> Bool
    {
        // Case 1 - we have just bytes
        if byteAligned
        {
            // Case 1.a - we have just bytes and we are adding just bytes
            if bits.byteAligned
            {
                guard pack(bytes: bits.buffer) else
                {
                    return false
                }
                
                leftover = nil
                
                return true
            }
            else if bits.buffer.count == 0 // Case 1.b - we have just bytes we are adding just bits
            {
                guard let rest = bits.leftover else { return false }
                
                // Case 1.b.i - we have just bytes and we are adding just bits that make up a full byte
                if rest.byteAligned
                {
                    // Simplifies to Case 1.a
                    let onlyBytes = Bits(data: rest.data, bits: nil)
                    guard pack(bits: onlyBytes) else { return false }
                    
                    return true
                }
                else // Case 1.b.ii - we have just bytes and we are adding just bits that do not make up a full byte

                {
                    // Copy bits
                    leftover = rest

                    return true
                }
            }
            else // Case 1.c - we have just bytes and we are adding both bytes and bits
            {
                // Case 1.c decomposes into Case 1.a followed by Case 1.b
                let onlyBytes = Bits(data: bits.buffer, bits: nil)
                let onlyBits = Bits(data: nil, bits: bits.leftover)
                
                guard pack(bits: onlyBytes) else { return false }
                guard pack(bits: onlyBits) else { return false }
                
                return true
            }
        }
        else // Case 2 - we have bits (and maybe also bytes)
        {
            let neededForAlignment = 8 - (count % 8)
            
            // Case 2.a - we have bits and we are adding the exact number of bits for alignment
            if bits.count == neededForAlignment
            {
                guard bits.buffer.count == 0 else
                {
                    return false
                }
                
                guard let rest = bits.leftover else
                {
                    return false
                }
                
                guard var partial = leftover else
                {
                    return false
                }
                
                guard partial.pack(bits: rest) else
                {
                    return false
                }
                
                guard partial.byteAligned else
                {
                    return false
                }
                
                let byte = partial.data
                buffer.append(byte)
                leftover = nil
                
                return true
            }
            else if bits.count > neededForAlignment // Case 2.b - we have bits and we are adding enough bits for alignment and then some

            {
                var mbits = bits // make a mutable copy
                guard let aligning = mbits.unpack(bits: neededForAlignment) else
                {
                    return false
                }
                
                guard pack(bits: aligning) else {
                    return false
                }
                
                guard pack(bits: bits) else {
                    return false
                }
                
                return true
            }
            else if var partial = leftover // bits.count < neededForAlignment - Case 2.c - we have bits and we are adding bits, but not enough for alignment - note this implies we are adding just bits and no bytes
            {
                guard bits.buffer.count == 0 else
                {
                    return false
                }
                
                guard let rest = bits.leftover else
                {
                    return false
                }
                                                
                guard partial.pack(bits: rest) else
                {
                    return false
                }
                
                leftover = partial
                
                return true
            }
            else // bits.count < neededForAlignment, leftover == nil - Case 2.d - we have nothing and we are adding bits, but not enough for alignment - note this implies we are adding just bits and no bytes
            {
                guard bits.buffer.count == 0 else
                {
                    return false
                }
                
                guard let rest = bits.leftover else
                {
                    return false
                }

                var partial = SimpleBits()
                guard partial.pack(bits: rest) else
                {
                    return false
                }
                
                leftover = partial
                
                return true
            }
        }
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
        guard bits <= count else { return nil }

        // Case 1 - we have just bytes
        if byteAligned
        {
            // Case 1.a - we have just bytes and we need just bytes
            if bits % 8 == 0 // This also covers the case where bits == 8
            {
                guard let bytes = unpack(bytes: bits/8) else
                {
                    return nil
                }
                
                return Bits(data: bytes, bits: nil)
            }
            else if bits < 8 // Case 1.b - we have just bytes and we need bits from just the first byte
            {
                // Get the first byte
                guard let data = unpack(bytes: 1) else
                {
                    return nil
                }

                // Working with a single byte is a job for SimpleBits
                guard var bytebits = SimpleBits(data: data) else
                {
                    return nil
                }

                guard let result = bytebits.unpack(bits: bits) else
                {
                    return nil
                }
                
                leftover = bytebits
                
                return Bits(data: nil, bits: result)
            }
            else // bits > 8 - Case 1.c - we have just bytes and we need bits from multiple bytes
            {
                let bytes = bits / 8
                let remainingBits = bits % 8 // remainingBits will always be less than 8
                
                // This case decomposes into Case 1.a, followed by Case 1.b
                // Execute Case 1.a
                guard let bytesResult = unpack(bytes: bytes) else
                {
                    return nil
                }

                // Execute Case 1.b
                guard let bitsResult = unpack(bits: remainingBits) else
                {
                    return nil
                }

                // Combine the results
                var result = Bits(data: bytesResult)
                guard result.pack(bits: bitsResult) else
                {
                    return nil
                }
                
                return result
            }
        }
        else if buffer.count == 0 // Case 2 - we have just bits
        {
            // We have already checked above that bits < count.
            
            // Getting bits from bits (without bytes) is a job for SimpleBits
            guard var bs = leftover else
            {
                return nil
            }

            guard let result = bs.unpack(bits: bits) else
            {
                return nil
            }

            // Convert the SimpleBits result back into Bits
            return Bits(data: nil, bits: result)
        }
        else // Case 3 - we have both bytes and bits
        {
            guard let rest = leftover else
            {
                return nil
            }
            
            let bytesBitCount = count - rest.count
            if bits <= bytesBitCount // Case 3.a - we can get the bits we need from just the bytes
            {
                // This decomposes to Case 1, followed by recombining the leftover bits
                
                // Temporarily remove the bits portion
                leftover = nil

                // Execute Case 1
                guard let result = unpack(bits: bits) else
                {
                    return nil
                }
                
                // Repack the bits portion
                guard pack(bits: Bits(data: nil, bits: leftover)) else
                {
                    return nil
                }
                
                return result
            }
            else // Case 3.b - we need to access both the bytes and bits to get the bits we need
            {
                // This decomposes to Case 3.a, followed by Case 2, and then combining the results.
                
                // We know from checks above the following facts:
                // - we have enough total bits to fulfill the request
                // - we do not have enough bits in just the bytes portion to fulfill the request
                // Implication: we will use all of the bytes portion and some of the bits portion
                
                // Execute Case 3.a
                // bytesBitCount is the number of bits we can retrieve from just the bytes portion
                guard var result = unpack(bits: bytesBitCount) else
                {
                    return nil
                }
                
                // Execute Case 2 to get the remaining bits needed
                guard let additional = unpack(bits: bits - bytesBitCount) else
                {
                    return nil
                }

                // Combine the results
                guard result.pack(bits: additional) else
                {
                    return nil
                }
                
                return result
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

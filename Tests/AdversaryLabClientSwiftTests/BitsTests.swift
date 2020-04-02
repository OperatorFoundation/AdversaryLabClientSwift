import XCTest
@testable import AdversaryLabClient

final class BitsTests: XCTestCase
{
    // SimpleBits tests
    func testSimpleBitsUnpackEmpty()
    {
        var bits = SimpleBits()
        
        let bit = bits.unpackBit()
        XCTAssertNil(bit)
    }
    
    func testSimpleBitsUnpackOnes()
    {
        guard var bits = SimpleBits(data: Data(array: [0b11111111])) else
        {
            XCTFail()
            return
        }
        
        for _ in [0..<8]
        {
            let bit = bits.unpackBit()
            XCTAssertEqual(bit, 1)
        }
    }
    
    func testSimpleBitsUnpackOnesAndZeros()
    {
        guard var bits = SimpleBits(data: Data(array: [0b11110000])) else
        {
            XCTFail()
            return
        }

        guard var ones = bits.unpack(bits: 4) else
        {
            XCTFail()
            return
        }

        
        guard var zeros = bits.unpack(bits: 4) else
        {
            XCTFail()
            return
        }
        
        for _ in 0..<4
        {
            let bit = ones.unpackBit()
            XCTAssertEqual(bit, 1)
        }
        
        for _ in 0..<4
        {
            let bit = zeros.unpackBit()
            XCTAssertEqual(bit, 0)
        }
    }
    
    func testSimpleBitsPack()
    {
        var bits = SimpleBits()
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))

        let data = bits.data
        
        guard data.count == 1 else
        {
            XCTFail()
            return
        }
        
        let byte = data[0]
        XCTAssertEqual(byte, 0b11111111)
    }
    
    func testSimpleBitsPackUnpack()
    {
        var bits = SimpleBits()
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 1))
        XCTAssertTrue(bits.pack(bit: 0))
        XCTAssertTrue(bits.pack(bit: 0))
        XCTAssertTrue(bits.pack(bit: 0))
        XCTAssertTrue(bits.pack(bit: 0))

        guard var ones = bits.unpack(bits: 4) else
        {
            XCTFail()
            return
        }

        
        guard var zeros = bits.unpack(bits: 4) else
        {
            XCTFail()
            return
        }
        
        for _ in 0..<4
        {
            let bit = ones.unpackBit()
            XCTAssertEqual(bit, 1)
        }
        
        for _ in 0..<4
        {
            let bit = zeros.unpackBit()
            XCTAssertEqual(bit, 0)
        }
    }
    
    func testSimpleBitsPackPack()
    {
        var bits = SimpleBits()
        
        var ones = SimpleBits()
        XCTAssertTrue(ones.pack(bit: 1))
        XCTAssertTrue(ones.pack(bit: 1))
        XCTAssertTrue(ones.pack(bit: 1))
        XCTAssertTrue(ones.pack(bit: 1))

        XCTAssertTrue(bits.pack(bits: ones))
        XCTAssertTrue(bits.pack(bits: ones))

        let data = bits.data
        
        guard data.count == 1 else
        {
            XCTFail()
            return
        }
        
        let byte = data[0]
        XCTAssertEqual(byte, 0b11111111)
    }
    
    // Bits tests
    func testBitsUnpackBitsEmpty()
    {
        var bits = Bits()
        
        let bit = bits.unpack(bits: 1)
        XCTAssertNil(bit)
    }
    
    func testBitsUnpackBytesEmpty()
    {
        var bits = Bits()
        
        let byte = bits.unpack(bytes: 1)
        XCTAssertNil(byte)
    }
    
    func testBitsUnpackBytes()
    {
        var bits = Bits(data: Data(array: [255]))
        
        guard let data = bits.unpack(bytes: 1) else
        {
            XCTFail()
            return
        }
        
        guard data.count == 1 else
        {
            XCTFail()
            return
        }
        
        let byte = data[0]
        XCTAssertEqual(byte, 255)
    }
    
    func testBitsUnpackBits()
    {
        var bits = Bits(data: Data(array: [255]))
        
        guard var result = bits.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        
        guard result.count == 1 else
        {
            XCTFail()
            return
        }
        
        guard let bit = result.unpackBit() else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(bit, 1)
    }
    
    func testSimpleBitsIntableUint8_0()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(0))
    }
    
    func testSimpleBitsIntableUint8_1()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(1))
    }

    func testSimpleBitsIntableUint8_2()
    {
        var bits = SimpleBits()
        
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
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(2))
    }
    
    func testSimpleBitsIntableUint8_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(3))
    }
    
    func testSimpleBitsIntableUint16_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint16 = bits.uint16 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint16, UInt16(3))
    }
    
    func testSimpleBitsIntableUint64_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint64 = bits.uint64 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint64, UInt64(3))
    }
    
    func testSimpleBitsIntableInt8_0()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(0))
    }
    
    func testSimpleBitsIntableInt8_1()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(1))
    }

    func testSimpleBitsIntableInt8_2()
    {
        var bits = SimpleBits()
        
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
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(2))
    }
    
    func testSimpleBitsIntableInt8_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(3))
    }
    
    func testSimpleBitsIntableInt16_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int16 = bits.int16 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int16, Int16(3))
    }
    
    func testSimpleBitsIntableInt64_3()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int64 = bits.int64 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int64, Int64(3))
    }
    
    func testSimpleBitsIntableInt8_Negative127()
    {
        var bits = SimpleBits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(-127))
    }
    
    func testSimpleBitsIntableInt8_Negative1()
    {
        var bits = SimpleBits()
        
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

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(-1))
    }
    
    func testSimpleBitsIntableInt8_Negative3()
    {
        var bits = SimpleBits()
        
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

        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(-3))
    }
    
    func testBitsIntableUInt8_0()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(0))
    }
    
    func testBitsIntableUInt8_1()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(1))
    }
    
    func testBitsIntableUInt8_2()
    {
        var bits = Bits()
        
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
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(2))
    }
    
    func testBitsIntableUInt8_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint8 = bits.uint8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint8, UInt8(3))
    }
    
    func testBitsIntableUInt16_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint16 = bits.uint16 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint16, UInt16(3))
    }
    
    func testBitsIntableUInt64_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let uint64 = bits.uint64 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(uint64, UInt64(3))
    }
    
    func testBitsIntableInt8_0()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(0))
    }
    
    func testBitsIntableInt8_1()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(1))
    }
    
    func testBitsIntableInt8_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int8 = bits.int8 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int8, Int8(3))
    }

    func testBitsIntableInt16_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int16 = bits.int16 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int16, Int16(3))
    }
    
    func testBitsIntableInt64_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int64 = bits.int64 else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int64, Int64(3))
    }
    
    func testBitsIntableInt_3()
    {
        var bits = Bits()
        
        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }

        guard bits.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        guard let int = bits.int else
        {
            XCTFail()
            return
        }
        
        XCTAssertEqual(int, Int(3))
    }
    
    func testBitsIntableInt16_bytes()
    {
        var bits = Bits()
        let test: Data = Data(array: [0x08, 0x00])

        guard bits.pack(bytes: test) else //pack doesn't add the bytes to the bits var
        {
            XCTFail()
            return
        }
        
        guard let int16 = bits.int16 else
        {
            XCTFail()
            return
        }
        
        let result = int16.data
        
        XCTAssertEqual(test, result)
     }
    
    func testBitsIntableInt_bytes()
    {
        let correct = Data(array: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00])
        
        var bits = Bits()
        let test: Data = Data(array: [0x08, 0x00])

        guard bits.pack(bytes: test) else //pack doesn't add the bytes to the bits var
        {
            XCTFail()
            return
        }
         
        guard let int = bits.int else
        {
            XCTFail()
            return
        }
         
        let result = int.data
         
        XCTAssertEqual(correct, result)
    }
    
    func testBits_PackUnpackBytes()
    {
        var bits = Bits()
        let test: Data = Data(array: [0x08, 0x00])

        guard bits.pack(bytes: test) else //pack doesn't add the bytes to the bits var
        {
            XCTFail()
            return
        }
        
        guard let result = bits.unpack(bytes: 2) else
        {
            XCTFail()
            return
        }
                
        XCTAssertEqual(test, result)
     }
}

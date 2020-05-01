import XCTest
@testable import AdversaryLabClient

final class BitsTests: XCTestCase
{
    //MARK: SimpleBits tests
    func testSimpleBits_FailableInit()
    {
        // Should not fail
        let sb1 = SimpleBits()
        XCTAssertNotNil(sb1)

        // Should not fail
        let sb2 = SimpleBits(data: Data(array: []))
        XCTAssertNotNil(sb2)
        
        // Should not fail
        let sb3 = SimpleBits(data: Data(array: [0x0A]))
        XCTAssertNotNil(sb3)

        // Should fail
        let sb4 = SimpleBits(data: Data(array: [0x0A, 0x0B]))
        XCTAssertNil(sb4)        
    }
    
    func testSimpleBits_EmptyData()
    {
        let correct = Data()
        
        let sb1 = SimpleBits()
        let data1 = sb1.data
        XCTAssertNotNil(data1)
        XCTAssertEqual(data1.count, 0)
        XCTAssertEqual(data1, correct)
    }
    
    func testSimpleBits_Data()
    {
        let sb1 = SimpleBits()
        let data1 = sb1.data
        XCTAssertNotNil(data1)
        XCTAssertEqual(data1.count, 0)
        
        var sb2 = SimpleBits()
        guard sb2.pack(bit: 0) else
        {
            XCTFail()
            return
        }
        let data2 = sb2.data
        XCTAssertNotNil(data2)
        XCTAssertEqual(data2.count, 1)

        guard let sb3 = SimpleBits(data: Data(array: [0x0A])) else
        {
            XCTFail()
            return
        }
        let data3 = sb3.data
        XCTAssertNotNil(data3)
        XCTAssertEqual(data3.count, 1)
    }
    
    func testSimpleBits_Overpack()
    {
        var sb = SimpleBits()
        
        for _ in 0..<8
        {
            // Should not fail
            XCTAssertTrue(sb.pack(bit: 0))
        }
        
        // Should fail
        XCTAssertFalse(sb.pack(bit: 0))

        // Should not fail
        var sb2 = SimpleBits()
        XCTAssertTrue(sb2.pack(bit: 0))
        
        // Should fail
        XCTAssertFalse(sb.pack(bits: sb2))
    }
    
    func testSimpleBits_Badpack()
    {
        var sb = SimpleBits()
                
        // Should fail
        XCTAssertFalse(sb.pack(bit: 12))
    }

    func testSimpleBits_Set()
    {
        guard var sb = SimpleBits(data: Data(array: [0xCC])) else
        {
            XCTFail()
            return
        }
                
        // Should not fail
        XCTAssertTrue(sb.set(bit: 0, index: 0))
        XCTAssertTrue(sb.set(bit: 1, index: 1))
        XCTAssertTrue(sb.set(bit: 0, index: 2))
        XCTAssertTrue(sb.set(bit: 1, index: 3))
        XCTAssertTrue(sb.set(bit: 0, index: 4))
        XCTAssertTrue(sb.set(bit: 1, index: 5))
        XCTAssertTrue(sb.set(bit: 0, index: 6))
        XCTAssertTrue(sb.set(bit: 1, index: 7))
        
        // Should fail
        XCTAssertFalse(sb.set(bit: 0, index: -1))
        XCTAssertFalse(sb.set(bit: 1, index: 8))
        XCTAssertFalse(sb.set(bit: 0, index: -8))
        XCTAssertFalse(sb.set(bit: 1, index: 500))
        XCTAssertFalse(sb.set(bit: 2, index: 4))
        XCTAssertFalse(sb.set(bit: 255, index: 5))
        XCTAssertFalse(sb.set(bit: 2, index: -1))
        XCTAssertFalse(sb.set(bit: 255, index: 255))
    }
    
    func testSimpleBits_Badunpack()
    {
        var sb = SimpleBits(data: Data(array: [0x3B]))
                
        // Should fail
        XCTAssertNil(sb?.unpack(bits: 0))
        
        // Should fail
        XCTAssertNil(sb?.unpack(bits: -1))
        
        // Should fail
        XCTAssertNil(sb?.unpack(bits: 9))
        
        // Should fail
        XCTAssertNil(sb?.unpack(bits: 576))
        
        // Should fail
        XCTAssertNil(sb?.unpack(bits: -576))
    }
    
    func testSimpleBits_Emptypack()
    {
        var sb = SimpleBits()
        let sb2 = SimpleBits()
                
        // Should not fail
        XCTAssertTrue(sb.pack(bits: sb2))
    }
    
    func testSimpleBitsUnpackEmpty()
    {
        var bits = SimpleBits()
        
        let bit = bits.unpackBit()
        XCTAssertNil(bit)
        
        let bs = bits.unpack(bits: 1)
        XCTAssertNil(bs)
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
    
    //MARK: Test SimplBits+MaybeIntable
    
    func testSimplBits_MaybeIntable()
    {
        let correctUint: UInt = 15
        let correctUint8: UInt8 = 15
        let correctUint16: UInt16 = 15
        let correctUint32: UInt32 = 15
        let correctUint64: UInt64 = 15

        let correctInt: Int = 15
        let correctInt8: Int8 = 15
        let correctInt16: Int16 = 15
        let correctInt32: Int32 = 15
        let correctInt64: Int64 = 15
        
        let sb1 = SimpleBits(byte: 0x0F)
        
        let uint = sb1.uint
        XCTAssertNotNil(uint)
        XCTAssertEqual(uint, correctUint)
        
        let uint8 = sb1.uint8
        XCTAssertNotNil(uint8)
        XCTAssertEqual(uint8!, correctUint8)
        
        let uint16 = sb1.uint16
        XCTAssertNotNil(uint16)
        XCTAssertEqual(uint16!, correctUint16)

        let uint32 = sb1.uint32
        XCTAssertNotNil(uint32)
        XCTAssertEqual(uint32!, correctUint32)
        
        let uint64 = sb1.uint64
        XCTAssertNotNil(uint64)
        XCTAssertEqual(uint64!, correctUint64)
        
        let int = sb1.int
        XCTAssertNotNil(int)
        XCTAssertEqual(int, correctInt)
        
        let int8 = sb1.int8
        XCTAssertNotNil(int8)
        XCTAssertEqual(int8!, correctInt8)
        
        let int16 = sb1.int16
        XCTAssertNotNil(int16)
        XCTAssertEqual(int16!, correctInt16)

        let int32 = sb1.int32
        XCTAssertNotNil(int32)
        XCTAssertEqual(int32!, correctInt32)
        
        let int64 = sb1.int64
        XCTAssertNotNil(int64)
        XCTAssertEqual(int64!, correctInt64)
    }
    
    //MARK: Bits tests
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
    
    // MARK: Bits tests
    func testBits_EmptyData()
    {
        let correct = Data()
        
        let b1 = Bits()
        let data1 = b1.data
        XCTAssertNotNil(data1)
        XCTAssertEqual(data1.count, 0)
        XCTAssertEqual(data1, correct)
    }
    
    func testBits_EmptyUnpackBytes()
    {
        var b1 = Bits()
        let result = b1.unpack(bytes: 1)
        XCTAssertNil(result)
    }

    func testBits_UnpackBytesZero()
    {
        var b1 = Bits()
        let result = b1.unpack(bytes: 0)
        XCTAssertNil(result)
    }

    func testBits_UnpackBytesOverflow()
    {
        var b1 = Bits(data: Data(array: [0xBB, 0xCC]))
        let result = b1.unpack(bytes: 3)
        XCTAssertNil(result)
    }
    
    func testBits_PackEmpty()
    {
        var b1 = Bits()
        let b2 = Bits()
        let success = b1.pack(bits: b2)
        XCTAssertTrue(success)
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

        guard bits.pack(bytes: test) else
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

        guard bits.pack(bytes: test) else
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
    
    func testBitsIntableInt_endianness()
    {
        let correct = Int(0x0800)
        
        var bits = Bits()
        let test: Data = Data(array: [0x08, 0x00])

        guard bits.pack(bytes: test) else
        {
            XCTFail()
            return
        }
         
        guard let result = bits.int else
        {
            XCTFail()
            return
        }
                  
        XCTAssertEqual(correct, result)
    }
    
    func testBits_packBytesAndBits()
    {
        var bits1 = Bits()
        let data1: Data = Data(array: [0x08, 0x00])

        // Construct a Bits with both bytes and bits
        guard bits1.pack(bytes: data1) else
        {
            XCTFail()
            return
        }
        
        guard bits1.pack(bit: 1) else
        {
            XCTFail()
            return
        }
        
        // Construct a Bits with just bytes
        var bits2 = Bits(data: data1)
        
        // Pack
        guard bits2.pack(bits: bits1) else
        {
            XCTFail()
            return
        }
    }

    func testBits_emptyUnpackBit()
    {
        var bits1 = Bits()

        let bit = bits1.unpackBit()
        XCTAssertNil(bit)
    }

    func testBits_unpackBitsZero()
    {
        var bits1 = Bits(data: Data(array: [0xFF]))

        let bit = bits1.unpack(bits: 0)
        XCTAssertNil(bit)
    }
    
    func testBits_unpackBitsFromMultipleBytes()
    {
        var bits1 = Bits(data: Data(array: [0xAB, 0xCD]))
        
        let bits = bits1.unpack(bits: 9)
        XCTAssertNotNil(bits)
    }
    
    func testBits_PackUnpackBytes()
    {
        var bits = Bits()
        let test: Data = Data(array: [0x08, 0x00])

        guard bits.pack(bytes: test) else
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
    
    func testBits_UnpackBitsThenBytes()
    {
        let correct = Data(array: [0b01010101])
        
        var bits = Bits()
        let input: Data = Data(array: [0b10101010, 0b11111111])

        guard bits.pack(bytes: input) else
        {
            XCTFail()
            return
        }
        
        guard let _ = bits.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        
        guard let result = bits.unpack(bytes: 1) else
        {
            XCTFail()
            return
        }
                
        print("Results: \(String(result[0], radix: 2)) \(String(result[0], radix: 2))")
        
        XCTAssertEqual(result, correct)
     }
    
    func testBits_UnpackBytesUInt16()
    {
        let correct: UInt16 = 257
        
        var bits = Bits()
        let input: Data = Data(array: [0x01, 0x01])

        guard bits.pack(bytes: input) else
        {
            XCTFail()
            return
        }
        
        guard let unpacked = bits.unpack(bytes: 2) else
        {
            XCTFail()
            return
        }
        
        let result = unpacked.uint16
                        
        XCTAssertEqual(result, correct)
     }
    
    func testBitsIntableUInt16_withLeftovers()
    {
        let correct: UInt16 = 4056
        
        var bits = Bits()
        let test: Data = Data(array: [0x7e])
        
        guard bits.pack(bytes: test) else
        {
            XCTFail()
            return
        }
        //11000000
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

        guard let uint16 = bits.uint16 else //fails here
        {
            XCTFail()
            return
        }
       
        XCTAssertEqual(uint16, correct)
    }
    
    func testBits__()
    {
        //offsetReservedFlags: 0x8018 - 0b1000 000 0 0 0 0   1 1   0 0 0
        //                                 a    b  c d e f   g h   i j k

        let input: Data = Data(array: [0x80, 0x18])
        var toUnpack = Bits(data: input)
      
        guard let a = toUnpack.unpack(bits: 4) else
        {
            XCTFail()
            return
        }
        guard let aUint8 = a.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(aUint8, 0b1000)
        
        
        guard let b = toUnpack.unpack(bits: 3) else
        {
            XCTFail()
            return
        }
        guard let bUint8 = b.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(bUint8, 0b000)
        
        
        guard let c = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let cUint8 = c.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(cUint8, 0b0)
        
        guard let d = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let dUint8 = d.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(dUint8, 0b0)
        
        guard let e = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let eUint8 = e.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(eUint8, 0b0)
        
        guard let f = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let fUint8 = f.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(fUint8, 0b0)
        
        
        
        
        guard let g = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let gUint8 = g.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(gUint8, 0b1)
        
        guard let h = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let hUint8 = h.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(hUint8, 0b1)
        
        
        
        guard let i = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let iUint8 = i.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(iUint8, 0b0)
        
        guard let j = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let jUint8 = j.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(jUint8, 0b0)
        
        guard let k = toUnpack.unpack(bits: 1) else
        {
            XCTFail()
            return
        }
        guard let kUint8 = k.uint8 else {
            XCTFail()
            return
            
        }
        XCTAssertEqual(kUint8, 0b0)
        
    }
    
    
}

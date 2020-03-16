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
}

//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation
import Rethink
import Dispatch
import Song
import InternetProtocols

public struct SongClient
{
    var packetDatabase: [RawPacket] = []

    mutating func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        for incomingInput in conn.Incoming
        {
            guard let incoming = makePacket(input: incomingInput, allowBlock: allowBlock, inOut: true, handshake: false) else
            {
                continue
            }
            
            packetDatabase.append(incoming)
        }
        
        for outgoingInput in conn.Outgoing
        {
            guard let outgoing = makePacket(input: outgoingInput, allowBlock: allowBlock, inOut: false, handshake: false) else
            {
                continue
            }
            
            packetDatabase.append(outgoing)
        }
    }
    
    mutating func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        if let incoming = makePacket(input: conn.Incoming, allowBlock: allowBlock, inOut: true, handshake: true)
        {
            packetDatabase.append(incoming)
        }
        
        if let outgoingInput = conn.Outgoing
        {
            if let outgoing = makePacket(input: outgoingInput, allowBlock: allowBlock, inOut: false, handshake: true)
            {
                packetDatabase.append(outgoing)
            }
        }
    }
    
    func makePacket(input: Packet, allowBlock: Bool, inOut: Bool, handshake: Bool) -> RawPacket?
    {
        let connID = connectionUUID()
        
        guard let EthernetPacket = input.ethernet else { return nil }
        guard let IPpacket = input.ipv4 else { return nil }
        guard let TCPsegment = input.tcp else { return nil }
        
        guard  let tcp_packet = IPpacket.payload, let payload = TCPsegment.payload else { return nil }
        return RawPacket(
            connection: connID,
            ip_packet: EthernetPacket.payload,
            tcp_packet: tcp_packet,
            payload: payload,
            timestamp: input.timestamp,
            allow_block: allowBlock,
            in_out: inOut,
            handshake: handshake
        )
    }
    
    func saveWithSong()
    {
        print("Saving \(packetDatabase.count) packets with song")
        let songEncoder = SongEncoder()
        guard let encodedBytes = try? songEncoder.encode(packetDatabase) else
        {
            return
        }

        let encoded = String(data: encodedBytes)
        print("Song Encoded:")
        print(encoded)
        
        let dir = URL(fileURLWithPath: "packetDatabase", isDirectory: true)
        do
        {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false, attributes: nil)
        }
        catch
        {
            print("Could not create directory \(error)")
        }
        
        let uuid = UUID().uuidString
        let file = URL(fileURLWithPath: uuid, relativeTo: dir)
        
        do
        {
            try encodedBytes.write(to: file)
        }
        catch
        {
            print("Could not write file \(error)")
        }
    }
}

public func ConnectSong(callback: @escaping (SongClient?) -> Void)
{
    callback(SongClient())
}
    
public func connectionUUID() -> String
{
    return UUID().uuidString
}

//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation
import Dispatch
import Symphony
import InternetProtocols
import RawPacket

public struct SongClient
{
    let db = Symphony(root: URL(fileURLWithPath: "adversary_data"))
    
    mutating func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        guard var sequence = db.createOrReadSequence(elementType: RawPacket.self, at: URL(fileURLWithPath: transport)) else
        {
            return
        }
        
        for incomingInput in conn.Incoming
        {
            guard let incoming = makePacket(input: incomingInput, allowBlock: allowBlock, inOut: true, handshake: false) else
            {
                continue
            }

            sequence.append(incoming)
        }
        
        for outgoingInput in conn.Outgoing
        {
            guard let outgoing = makePacket(input: outgoingInput, allowBlock: allowBlock, inOut: false, handshake: false) else
            {
                continue
            }

            sequence.append(outgoing)
        }
    }
    
    mutating func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        guard var sequence = db.createOrReadSequence(elementType: RawPacket.self, at: URL(fileURLWithPath: transport)) else
        {
            return
        }

        if let incoming = makePacket(input: conn.Incoming, allowBlock: allowBlock, inOut: true, handshake: true)
        {
            sequence.append(incoming)
        }
        
        if let outgoingInput = conn.Outgoing
        {
            if let outgoing = makePacket(input: outgoingInput, allowBlock: allowBlock, inOut: false, handshake: true)
            {
                sequence.append(outgoing)
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
}

public func ConnectSong(callback: @escaping (SongClient?) -> Void)
{
    callback(SongClient())
}
    
public func connectionUUID() -> String
{
    return UUID().uuidString
}

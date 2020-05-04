//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation
import AdversaryLabClient
import Rethink
import Dispatch
import Song

let packetsKey: String = "Packets"

public struct RawPacket: Codable {
    let connection: String
    let ip_packet: Data
    let tcp_packet: Data
    let payload: Data
    let timestamp: Int
    let allow_block: Bool
    let in_out: Bool
    let handshake: Bool
}

public struct ConnectionPackets
{ //first incoming/outgoing relative to server
    var Incoming: Packet
    var Outgoing: Packet?
}

public struct RawConnectionPackets
{ //all packets
    var Incoming: [Packet] = []
    var Outgoing: [Packet] = []
}

public struct Client
{
    let connection: ReConnection
    
    func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        print("addtrainpk")
        let connID = connectionID()
        
        guard let EthernetPacket = conn.Incoming.ethernet else { return }
        guard let IPpacket = conn.Incoming.ipv4 else { return }
        guard let TCPsegment = conn.Incoming.tcp else { return }
        
        let rawPacket: ReDocument = [
            "connection": connID,
            "ip_packet": EthernetPacket.payload,
            "tcp_packet": IPpacket.payload,
            "payload": TCPsegment.payload,
            "timestamp": conn.Incoming.timestamp,
            "allow_block": allowBlock,
            "in_out": true, //true = incoming
            "handshake": true //true because add train is only called for handshake packets
        ]

        R.dbCreate(transport).run(connection) { response in
            guard !response.isError else { return }

            R.db(transport).tableCreate(packetsKey).run(self.connection) { response in
                guard !response.isError else { return }
                
                R.db(transport).table(packetsKey).insert([rawPacket]).run(self.connection) { response in
                    guard !response.isError else { return }
                }
            }
        }
    }

    func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets, lastPacket: Bool, lock: DispatchGroup)
    {
        DispatchQueue.main.async
        {
            print("add raw train packet")
            if lastPacket
            {
                lock.leave()
                return
            }
        }
    }
    
    func AddTrainPacketSong(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        print("addtrainpk")
        let connID = connectionID()
        
        guard let EthernetPacket = conn.Incoming.ethernet else { return }
        guard let IPpacket = conn.Incoming.ipv4 else { return }
        guard let TCPsegment = conn.Incoming.tcp else { return }
        
        guard  let tcp_packet = IPpacket.payload, let payload = TCPsegment.payload else { return }
        let rawPacket = RawPacket(
            connection: connID,
            ip_packet: EthernetPacket.payload,
            tcp_packet: tcp_packet,
            payload: payload,
            timestamp: conn.Incoming.timestamp,
            allow_block: allowBlock,
            in_out: true, //true = incoming
            handshake: true //true because add train is only called for handshake packets
        )

        let songEncoder = SongEncoder()
        if let encodedBytes = try? songEncoder.encode(rawPacket)
        {
            let encoded = String(data: encodedBytes)
            print("Song Encoded:")
            print(encoded)
        }
    }
}

public func Connect(callback: @escaping (Client?) -> Void)
{
    guard let url = URL(string: "rethinkdb://localhost:28015") else {
        callback(nil)
        return
    }
    
    R.connect(url) { err, connection in
        guard err == nil else {
            print("error connecting to rethinkdb")
            callback(nil)
            return
        }
        callback(Client(connection: connection))
        return
    }
}
    
public func connectionID() -> String
{
    let timestampMicrosecs = Date().timeIntervalSince1970
    return timestampMicrosecs.string
}





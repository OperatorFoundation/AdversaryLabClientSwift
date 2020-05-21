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

public struct RawPacket: Codable
{
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
    var packetDatabase: [RawPacket] = []

    func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        print("addtrainpk")
        let connID = connectionID()
        
        guard let EthernetPacket = conn.Incoming.ethernet else
        {
            return
        }
        guard let IPpacket = conn.Incoming.ipv4 else
        {
            return
        }
        guard let TCPsegment = conn.Incoming.tcp else
        {
            return
        }
        guard let tcp_packet_bytes = IPpacket.payload else
        {
            return
        }
        guard let payload_bytes = TCPsegment.payload else
        {
            return
        }
        
        let rawPacket: ReDocument = [
            "connection": connID,
            "ip_packet": EthernetPacket.payload.base64EncodedString(),
            "tcp_packet": tcp_packet_bytes.base64EncodedString(),
            "payload": payload_bytes.base64EncodedString(),
            "timestamp": conn.Incoming.timestamp,
            "allow_block": allowBlock,
            "in_out": true, //true = incoming, false = outgoing
            "handshake": true //true because add train is only called for handshake packets
        ]
        
        print("Actually writing to database")
        self.lockReThink.enter()
        R.dbCreate(transport).run(connection)
        {
            response in
            print("add train packet - database callback was called")
            if response.isError
            {
                print("Error creating database \(response), perhaps already created")
            }
            
            R.db(transport).tableCreate(packetsKey).run(self.connection)
            {
                response in
                
                if response.isError
                {
                    print("Error creating table \(response), perhaps already created")
                }
                
                R.db(transport).table(packetsKey).insert([rawPacket]).run(self.connection)
                {
                    response in
                    
                    guard !response.isError else
                    {
                        print("Error inserting document")
                        self.lockReThink.leave()
                        return
                    }
                    print("Successfully wrote document to database.")
                    self.lockReThink.leave()
                }
            }
        }
        self.lockReThink.wait()
        
        if let outgoing = conn.Outgoing
        {
            guard let EthernetPacket = outgoing.ethernet else
            {
                return
            }
            guard let IPpacket = outgoing.ipv4 else
            {
                return
            }
            guard let TCPsegment = outgoing.tcp else
            {
                return
            }
            guard let tcp_packet_bytes = IPpacket.payload else
            {
                return
            }
            guard let payload_bytes = TCPsegment.payload else
            {
                return
            }
            
            let rawPacket: ReDocument = [
                "connection": connID,
                "ip_packet": EthernetPacket.payload.base64EncodedString(),
                "tcp_packet": tcp_packet_bytes.base64EncodedString(),
                "payload": payload_bytes.base64EncodedString(),
                "timestamp": conn.Incoming.timestamp,
                "allow_block": allowBlock,
                "in_out": false, //true = incoming, false = outgoing
                "handshake": true //true because add train is only called for handshake packets
            ]
            
            print("Actually writing to database")
            self.lockReThink.enter()
            R.dbCreate(transport).run(connection)
            {
                response in
                print("add train packet - database callback was called")
                if response.isError
                {
                    print("Error creating database \(response), perhaps already created")
                }
                
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    response in
                    
                    if response.isError
                    {
                        print("Error creating table \(response), perhaps already created")
                    }
                    
                    R.db(transport).table(packetsKey).insert([rawPacket]).run(self.connection)
                    {
                        response in
                        
                        guard !response.isError else
                        {
                            print("Error inserting document")
                            self.lockReThink.leave()
                            
                            
                            return
                        }
                        
                        print("Successfully wrote document to database.")
                        self.lockReThink.leave()
                    }
                }
            }
        }
    }
    
    func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        
        for packet in conn.Incoming
        {
            
            print("add raw train pk")
            let connID = connectionID()
            
            guard let EthernetPacket = packet.ethernet else
            {
                continue
            }
            guard let IPpacket = packet.ipv4 else
            {
                continue
            }
            guard let TCPsegment = packet.tcp else
            {
                continue
            }
            
            guard let tcp_packet_bytes = IPpacket.payload else
            {
                continue
            }
            
            guard let payload_bytes = TCPsegment.payload else
            {
                continue
            }
            
            let rawPacket: ReDocument = [
                "connection": connID,
                "ip_packet": EthernetPacket.payload.base64EncodedString(),
                "tcp_packet": tcp_packet_bytes.base64EncodedString(),
                "payload": payload_bytes.base64EncodedString(),
                "timestamp": packet.timestamp,
                "allow_block": allowBlock,
                "in_out": true, //true = incoming
                "handshake": false //
            ]
            
            print("Actually writing to database")
            
            self.lockReThink.enter()
            R.dbCreate(transport).run(connection)
            {
                response in
                print("add raw train packet incoming - database callback was called")
                
                if response.isError
                {
                    print("Error creating database \(response), perhaps already created")
                }
                
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    response in
                    
                    if response.isError
                    {
                        print("Error creating table \(response), perhaps already created")
                    }
                    
                    R.db(transport).table(packetsKey).insert([rawPacket]).run(self.connection)
                    {
                        response in
                        
                        guard !response.isError else
                        {
                            print("Error inserting document")
                            self.lockReThink.leave()
                            return
                        }
                        self.lockReThink.leave()
                        print("Successfully wrote document to database.")
                        
                    }
                }
            }
            self.lockReThink.wait()
        }
        
        for (index, packet) in conn.Outgoing.enumerated()
        {
            print("add raw train pk")
            let connID = connectionID()
            guard let EthernetPacket = packet.ethernet else
            {
                continue
            }
            guard let IPpacket = packet.ipv4 else
            {
                continue
            }
            guard let TCPsegment = packet.tcp else
            {
                continue
            }
            
            guard let tcp_packet_bytes = IPpacket.payload else
            {
                continue
            }
            guard let payload_bytes = TCPsegment.payload else
            {
                continue
            }
            
            let rawPacket: ReDocument = [
                "connection": connID,
                "ip_packet": EthernetPacket.payload.base64EncodedString(),
                "tcp_packet": tcp_packet_bytes.base64EncodedString(),
                "payload": payload_bytes.base64EncodedString(),
                "timestamp": packet.timestamp,
                "allow_block": allowBlock,
                "in_out": false, //true = incoming, false=outgoing
                "handshake": false //
            ]
            
            print("Actually writing to database")
            
            self.lockReThink.enter()
            R.dbCreate(transport).run(connection)
            {
                response in
                print("add raw train packet outgoing - database callback was called")
                
                if response.isError
                {
                    print("Error creating database \(response), perhaps already created")
                }
                
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    response in
                    
                    if response.isError
                    {
                        print("Error creating table \(response), perhaps already created")
                    }
                    
                    R.db(transport).table(packetsKey).insert([rawPacket]).run(self.connection)
                    {
                        response in
                        
                        guard !response.isError else
                        {
                            print("Error inserting document")
                            self.lockReThink.leave()
                            return
                        }
                        
                        print("Successfully wrote document to database.")
                        self.lockReThink.leave()
                        
                    }
                }
            }
            
            self.lockReThink.wait()
        }
    }
    
    mutating func AddTrainPacketSong(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        print("AddTrainPacketSong !!!")
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
        
        packetDatabase.append(rawPacket)
    }
    
    func saveWithSong()
    {
        print("Saving \(packetDatabase.count) packets with song")
        let songEncoder = SongEncoder()
        if let encodedBytes = try? songEncoder.encode(packetDatabase)
        {
            let encoded = String(data: encodedBytes)
            print("Song Encoded:")
            print(encoded)
        }
    }
}

public func Connect(callback: @escaping (Client?) -> Void)
{
    guard let url = URL(string: "rethinkdb://localhost:28015") else
    {
        callback(nil)
        return
    }
    
    R.connect(url) { err, connection in
        guard err == nil else
        {
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

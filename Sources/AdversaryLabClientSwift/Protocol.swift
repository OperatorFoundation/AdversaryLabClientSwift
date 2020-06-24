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

public struct ConnectionPackets: Codable
{ //first incoming/outgoing relative to server
    var Incoming: Packet
    var Outgoing: Packet?
}

public struct RawConnectionPackets: Codable
{ //all packets
    var Incoming: [Packet] = []
    var Outgoing: [Packet] = []
}

public struct Client
{
    let connection: ReConnection
    let lockReThink: DispatchGroup = DispatchGroup()
    var packetDatabase: [RawPacket] = []

    func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
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
        
        self.lockReThink.enter()
        
        // FIXME: Check if DB already exists.
        R.dbCreate(transport).run(connection)
        {
            (response) in
            
            if response.isError
            {
                //print("Error creating database \(response), perhaps already created")
            }
            
            // FIXME: Check if table already exists first
            R.db(transport).tableCreate(packetsKey).run(self.connection)
            {
                (response) in
                
                if response.isError
                {
                    //print("Error creating table \(response), perhaps already created")
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
            
            self.lockReThink.enter()
            
            // FIXME: Check if DB already exists.
            R.dbCreate(transport).run(connection)
            {
                (response) in
                
                if response.isError
                {
                    //print("Error creating database \(response), perhaps already created")
                }
                
                // FIXME: Check if table already exists first
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    (response) in
                    
                    if response.isError
                    {
                        //print("Error creating table \(response), perhaps already created")
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
                    }
                }
            }
        }
    }
    
    func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        
        for packet in conn.Incoming
        {
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
                        
            self.lockReThink.enter()
            
            // FIXME: Check if DB already exists.
            R.dbCreate(transport).run(connection)
            {
                (response) in
                
                if response.isError
                {
                    //print("Error creating database \(response), perhaps already created")
                }
                
                // FIXME: Check if table already exists first
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    (response) in
                    
                    if response.isError
                    {
                        //print("Error creating table \(response), perhaps already created")
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
                    }
                }
            }
            self.lockReThink.wait()
        }
        
        for (_, packet) in conn.Outgoing.enumerated()
        {
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
                        
            self.lockReThink.enter()
            
            // FIXME: Check if DB already exists.
            R.dbCreate(transport).run(connection)
            {
                (response) in
                
                if response.isError
                {
//                    guard let string: String = (response.value as? String) else { continue }
//                    if string.contains("Database `HTTPS` already exists")
//                    {
//                        
//                    }
                    //print("Error creating database \(response), perhaps already created")
                }
                
                // FIXME: Check if tablealready exists first
                R.db(transport).tableCreate(packetsKey).run(self.connection)
                {
                    (response) in
                    
                    if response.isError
                    {
                        //print("Error creating table \(response), perhaps already created")
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
                    }
                }
            }
            
            self.lockReThink.wait()
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
   return UUID().uuidString
}

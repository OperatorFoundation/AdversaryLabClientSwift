//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation
import AdversaryLabClient
import Rethink

let packetsKey: String = "Packets"

public struct RawPacket {
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
        
        guard let EthernetPacket = conn.Incoming.Ethernet else { return }
        guard let IPpacket = conn.Incoming.IPv4 else { return }
        guard let TCPsegment = conn.Incoming.TCP else { return }
        
        
        //conn.Incoming?.TCP.
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
        
        
//                    R.db(databaseName).table(tableName).indexWait().run(connection) { response in
//                        assert(!response.isError, "Failed to wait for index: \(response)")
//
//                        // Insert 1000 documents
//                        var docs: [ReDocument] = []
//                        for i in 0..<1000 {
//                            docs.append(["foo": "bar", "id": i])
//                        }
//
//                        R.db(databaseName).table(tableName).insert(docs).run(connection) { response in
//                            assert(!response.isError, "Failed to insert data: \(response)")
//
//                            R.db(databaseName).table(tableName).filter({ r in return r["foo"].eq(R.expr("bar")) }).run(connection) { response in
//                                ...
//                            }
//
//                            R.db(databaseName).table(tableName).count().run(connection) { response in
//                                ...
//                            }
//                        }
//                    }
//                }
//            }
//        }
        
        
        
    }

    func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        print("addrawtrainpk")
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
    
public func connectionID() -> String {
    let timestampMicrosecs = Date().timeIntervalSince1970
    return timestampMicrosecs.string
    
    
}





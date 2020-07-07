//
//  RawPacket.swift
//  
//
//  Created by Mafalda on 7/7/20.
//

import Foundation

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
    
    public init(connection: String, ip_packet: Data, tcp_packet: Data, payload: Data, timestamp: Int, allow_block: Bool, in_out: Bool, handshake: Bool)
    {
        self.connection = connection
        self.ip_packet = ip_packet
        self.tcp_packet = tcp_packet
        self.payload = payload
        self.timestamp = timestamp
        self.allow_block = allow_block
        self.in_out = in_out
        self.handshake = handshake
    }
}

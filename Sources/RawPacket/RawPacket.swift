//
//  RawPacket.swift
//  
//
//  Created by Mafalda on 7/7/20.
//

import Foundation

public struct RawPacket: Codable
{
    public let connection: String
    public let ip_packet: Data
    public let tcp_packet: Data
    public let payload: Data
    public let timestamp: Int
    public let allow_block: Bool
    public let in_out: Bool
    public let handshake: Bool
    
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

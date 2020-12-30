//
//  Connection.swift
//  
//
//  Created by Dr. Brandon Wiley on 12/29/20.
//

import Foundation
import InternetProtocols

struct Connection: Hashable
{
    let small: UInt16
    let big: UInt16
}

func NewConnection(packet: Packet) -> Connection?
{
    guard let TCPsegment = packet.tcp else { return nil }

    if TCPsegment.sourcePort < TCPsegment.destinationPort
    {
        return Connection(small: TCPsegment.sourcePort, big: TCPsegment.destinationPort)
    }
    else
    {
        return Connection(small: TCPsegment.destinationPort, big: TCPsegment.sourcePort)
    }
}

extension Connection
{
    func CheckPort(port: UInt16) -> Bool
    {
        return self.small == port || self.big == port
    }
}

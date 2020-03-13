//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation

struct ConnectionPackets
{
    var Incoming: TCP? = nil
    var Outgoing: TCP? = nil
}

struct RawConnectionPackets
{
    var Incoming: [TCP] = []
    var Outgoing: [TCP] = []
}

struct Client
{
    
}

func Connect() -> Client?
{
    return Client()
}

//
//  Protocol.swift
//  
//
//  Created by Dr. Brandon Wiley on 3/2/20.
//

import Foundation
import AdversaryLabClient

public struct ConnectionPackets
{
    var Incoming: TCP? = nil
    var Outgoing: TCP? = nil
}

public struct RawConnectionPackets
{
    var Incoming: [TCP] = []
    var Outgoing: [TCP] = []
}

public struct Client
{
    
}

public func Connect() -> Client?
{
    return Client()
}

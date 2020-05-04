//
//  State.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/4/20.
//

import Foundation
import SwiftQueue
import AdversaryLabClient
import SwiftPCAP

class State
{
    var maybeAllowBlock: Bool? = nil
    let allowBlockChannel: Queue<Bool> = Queue<Bool>()
    var captured: [Connection:ConnectionPackets] = [:]
    var rawCaptured: [Connection:RawConnectionPackets] = [:]
    let packetChannel: Queue<Packet> = Queue<Packet>()
    let recordable: Queue<ConnectionPackets> = Queue<ConnectionPackets>()
    let queue: DispatchQueue = DispatchQueue.init(label: "AdversaryLab")
    var debug_packetCount = 0
    var lab: Client
    let transport: String
    let port: UInt16
    var lock: DispatchGroup
    var recording: Bool
    
    init(transport: String, port: UInt16, client: Client)
    {
        self.transport = transport
        self.port = port
        self.lab = client
        
        self.lock = DispatchGroup()
        self.recording = true
    }    
    
    func listenForDataCategory()
    {
        var allowBlockWasSet = false
        var allowBlock = false
        
        while !allowBlockWasSet
        {
            print("-> Type 'allow' or 'block' when you are done recording <-\n")
            let text = readLine(strippingNewline: true)
            if text == "allow"
            {
                print("-> This packet data will be saved as allowed.")
                allowBlock = true
                allowBlockWasSet = true
            }
            else if text == "block"
            {
                print("-> This packet data will be saved as blocked.")
                allowBlock = false
                allowBlockWasSet = true
            }
            else
            {
                print("-> Received unexpected input for the connection data category please enter 'allowed' or 'blocked':\n \(String(describing: text))")
            }
        }
        
        // This tells us that we are done recording and the buffered packets
        // are either allowed or blocked based on user input.
        allowBlockChannel.enqueue(allowBlock)
    }
    
    func capture()
    {        
        #if os(OSX)
        let deviceName: String = "en0"
        #elseif os(Linux)
        let deviceName: String = "ens18"
        #else
        let deviceName: String = "eth0"
        #endif
        
        let packetChannel = Queue<Packet>()
        switch sourceReadFromFile
        {
            case 1 :
                guard let packetSource = try? SwiftPCAP.Offline(path: filePath) else
                {
                    print("-> Error opening file")
                    return
                }
                
                print("readPkts file")
                self.readPackets(source: packetSource, dest: packetChannel, port: port)
            
            default :
                guard let packetSource = try? SwiftPCAP.Live(interface: deviceName) else
                {
                    print("-> Error opening network device")
                    return
                }
                
                print("readPkts interface")
                self.readPackets(source: packetSource, dest: packetChannel, port: port)
        }
    }
    
    func readPackets(source: SwiftPCAP.Base, dest: Queue<Packet>, port: UInt16)
    {
        print("read packets")
        while self.recording
        {
            let bytes = source.nextPacket()
            
            if bytes.count == 0
            {
                print("\n\n_", terminator: "")
                
                if sourceReadFromFile == 1 //reading from file and have reached the end of file
                {
                    print("\n\nEnd of PCAP file reached\n")
                    return
                }
                
                sleep(1)
            }
            else
            {
                debug_packetCount += 1
                print("\n\nP# \(debug_packetCount) - bytes \(bytes.count):")
                printBytes(bytes)
                
                let thisPacket = Packet(rawBytes: Data(bytes))
                
                if thisPacket.tcp != nil
                {
                    capturePort(thisPacket, port)
                }
            }
        }
    }
    
    func printBytes(_ bytes: [UInt8])
    {
        var count = 0
        for byte in bytes
        {
            print(String(format: "%02x", byte), terminator: " ")
            count += 1
            if count % 8 == 0
            {
                print(" ", terminator: "")
            }
            if count % 16 == 0
            {
                print("")
            }
        }
        print("\n")
    }
    
    func capturePort(_ packet: Packet, _ port: UInt16)
    {
        print("-> Capturing port \(port)")
                
        guard let conn = NewConnection(packet: packet) else { return }
        guard conn.CheckPort(port: port) else { return }
        
        recordRawPacket(packet, port)
        
        if packet.tcp?.payload != nil
        {
            recordPacket(packet, port)
        }
    }
    
    func recordRawPacket(_ packet: Packet, _ port: UInt16)
    {
        print("Entered recordRawPacket")
        guard let conn = NewConnection(packet: packet) else { return }
        //let incoming = packet.destinationPort == port
        guard let TCPsegment = packet.tcp else { return }
        let incoming = TCPsegment.destinationPort == port
        
        var connPackets = rawCaptured[conn, default: RawConnectionPackets()]
        
        if incoming {
            connPackets.Incoming.append(packet)
            rawCaptured[conn] = connPackets
        } else {
            connPackets.Outgoing.append(packet)
            rawCaptured[conn] = connPackets
        }
    }
    
    func recordPacket(_ packet: Packet, _ port: UInt16)
    {
        print("recPkt")
        guard let conn = NewConnection(packet: packet) else { return }
        guard let TCPsegment = packet.tcp else { return }
        let incoming = TCPsegment.destinationPort == port
        var maybeConnPackets = captured[conn]
        
        // This is the first packet of the connection
        if maybeConnPackets == nil
        {
            if incoming
            {
                maybeConnPackets = ConnectionPackets(Incoming: packet, Outgoing: nil)
                captured[conn] = maybeConnPackets
            }
        }
        else
        {
            var connPackets = maybeConnPackets!
            
            // This is the second packet of the connection
            if !incoming && connPackets.Outgoing == nil
            {
                connPackets.Outgoing = packet
                captured[conn] = connPackets
                
                print("-> .")
                recordable.enqueue(connPackets)
            }
        }
    }
    
    func saveCaptured()
    {
        print("-> Saving captured raw connection packets... ")
        var buffer: [ConnectionPackets] = []
        var count = 0
        
        if !recordable.isEmpty
        {
            print("!")
            guard let connPackets = recordable.dequeue() else
            {
                print(".")
                return
            }
            
            if let allowBlock = maybeAllowBlock
            {
                print("**")
                guard let allowBlock = maybeAllowBlock else
                {
                    print("-")
                    return
                }
                
                print("*")
                lab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connPackets)
            }
            else
            {
                print("+")
                buffer.append(connPackets)
            }
        }
        
        print("@")
        guard let allowBlock = allowBlockChannel.dequeue() else
        {
            return
        }
        
        self.lock.enter()
        
        for packet in buffer
        {
            print("-> Saving complete connections. --<-@")
            lab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: packet)
        }
        
        if rawCaptured.count == 0
        {
            self.lock.leave()
            return
        }
        
        for (index, rawConnection) in rawCaptured.enumerated()
        {
            print("-> Saving complete raw connections. --<-@")
            var last: Bool = false
            if index == (rawCaptured.count - 1)
            {
                last = true
            }
            
            lab.AddRawTrainPacket(transport: transport, allowBlock: allowBlock, conn: rawConnection.value, lastPacket: last, lock: self.lock)
        }
        
        // Usually we want both incoming and outgoingf packets
        // In the case where we know these are blocked connections
        // We want to record the data even when we have not received a response.
        // This is still a valid blocked case. We expect that some blocked connections will behave in this way.
        
        //If the connections in this map are labeled blocked by the user
        print("newAllowBlock is ", allowBlock)
        if allowBlock == false
        {
            print("-> Captured count is ", captured.count)
            for (_, connection) in captured
            {
                print("Entering loop for saving incomplete connections.")
                // If this connection in the map is incomplete (only the incoming packet was captured) save it
                // Check this because a complete struct (both incoming and outgoing packets are populated)
                // will already be getting saved by the above for loop
                if connection.Outgoing == nil
                {
                    print("-> Saving incomplete connection.  --<-@")
                    lab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connection)
                }
            }
        }
        
        print("--> We are done saving things to the database. Bye now!\n")
        exit(1)
    }
}
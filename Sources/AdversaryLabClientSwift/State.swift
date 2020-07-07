//
//  State.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/4/20.
//

import Foundation
import SwiftQueue
import SwiftPCAP
import InternetProtocols

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

let packetsKey: String = "Packets"

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

class State
{
    var maybeAllowBlock: Bool? = nil
    let allowBlockChannel: Queue<Bool> = Queue<Bool>()
    var captured: [Connection:ConnectionPackets] = [:]
    var rawCaptured: [Connection:RawConnectionPackets] = [:]
    let packetChannel: Queue<Packet> = Queue<Packet>()
    let recordable: Queue<ConnectionPackets> = Queue<ConnectionPackets>()
    let queue: DispatchQueue = DispatchQueue(label: "AdversaryLab")
    var debug_packetCount = 0
    var debug_portMatchPacketsCount = 0
    var debug_payloadPacketsCount = 0
    var debug_recordedPacketsCount = 0
    var debug_recordedCompletePacketsCount = 0
    var debug_addTrainPacketCount = 0
    var debug_savedIncompletePacketCount = 0
    var songLab: SongClient
    let transport: String
    let port: UInt16
    var recording: Bool
    let signalQueue = DispatchQueue(label: "signal")
    
    init(transport: String, port: UInt16, songClient: SongClient)
    {
        self.transport = transport
        self.port = port
        songLab = songClient
        self.recording = true
        
    }    
    
    func listenForDataCategory()
    {
        var allowBlockWasSet = false
        var allowBlock = false
        
        while !allowBlockWasSet
        {
            print("-> Type 'allow' or 'block' when you are done recording <-\n")
            guard let text = readLine(strippingNewline: true) else
            {
                #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
                    _ = Darwin.raise(SIGINT)
                #elseif os(Linux)
                    _ = Glibc.raise(SIGINT)
                #endif
                return
            }
            
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
                print("-> Received unexpected input for the connection data category please enter 'allow' or 'block':\n \(String(describing: text))")
            }
        }
        // This tells us that we are done recording and the buffered packets
        // are either allowed or blocked based on user input.
        self.recording = false
        allowBlockChannel.enqueue(allowBlock)
        self.saveCaptured()
        exit(0)
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
        case true : //read from pcap file
            guard let packetSource = try? SwiftPCAP.Offline(path: validPCAPfile) else
            {
                print("-> Error opening file")
                return
            }
            self.readPackets(source: packetSource, dest: packetChannel, port: port)
            
        default : //read from network interface
            guard let packetSource = try? SwiftPCAP.Live(interface: deviceName) else
            {
                print("-> Error opening network device")
                return
            }
            
            self.readPackets(source: packetSource, dest: packetChannel, port: port)
        }
    }
    
    func readPackets(source: SwiftPCAP.Base, dest: Queue<Packet>, port: UInt16)
    {
        print("-> reading packets")
        while self.recording
        {
            let bytes = source.nextPacket()
            let timestamp = source.currentHeader.ts
            
            if bytes.count == 0
            {
                //print("\n_", terminator: "\n")
                
                if sourceReadFromFile //reading from file and have reached the end of file
                {
                    print("\n\nEnd of PCAP file reached.\n")
                    finishCapture()
                    return
                }
                
                sleep(1) //wait for a packet
            }
            else
            {
                debug_packetCount += 1
                //print("\n\nP# \(debug_packetCount) - bytes \(bytes.count):")
                // printBytes(bytes)
                
                let thisPacket = Packet(rawBytes: Data(bytes), timestamp: timestamp, debugPrints: false) //parse the packet
                
                if thisPacket.tcp != nil //capture tcp packet
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
        //print("-> Capturing port \(port)")

        guard let conn = NewConnection(packet: packet) else { return }
        
        //print(conn)
        
        guard conn.CheckPort(port: port) else { return }
        debug_portMatchPacketsCount += 1
        
        recordRawPacket(packet, port)
        
        if packet.tcp?.payload != nil
        {
            debug_payloadPacketsCount += 1
            recordPacket(packet, port)
        }
    }
    
    func recordRawPacket(_ packet: Packet, _ port: UInt16)
    {
        guard let conn = NewConnection(packet: packet) else { return }
        //let incoming = packet.destinationPort == port
        guard let TCPsegment = packet.tcp else { return }
        let incoming = TCPsegment.destinationPort == port
        
        var connPackets = rawCaptured[conn, default: RawConnectionPackets()]
        
        if incoming {
            connPackets.Incoming.append(packet)
            rawCaptured[conn] = connPackets
        }
        else
        {
            connPackets.Outgoing.append(packet)
            rawCaptured[conn] = connPackets
        }
    }
    
    func recordPacket(_ packet: Packet, _ port: UInt16)
    {
        guard let conn = NewConnection(packet: packet) else { return }
        guard let TCPsegment = packet.tcp else { return }
        let incoming = TCPsegment.destinationPort == port
        var maybeConnPackets = captured[conn]
        
        if maybeConnPackets == nil
        {
            // This is the first packet of the connection
            if incoming
            {
                maybeConnPackets = ConnectionPackets(Incoming: packet, Outgoing: nil)
                captured[conn] = maybeConnPackets
                debug_recordedPacketsCount += 1
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
                debug_recordedPacketsCount += 1
                debug_recordedCompletePacketsCount += 1
            }
        }
    }
    
    func saveCaptured()
    {
        print("-> Saving captured packets... ")
        print("recordable: \(!recordable.isEmpty)")
        var buffer: [ConnectionPackets] = []
        
        while !recordable.isEmpty
        {
            print("-> Saving complete connections")
            guard let connPackets = recordable.dequeue() else
            {
                print(".")
                return
            }
            
            if let allowBlock = maybeAllowBlock
            {
                print("-> *")
                songLab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connPackets)
                debug_addTrainPacketCount += 1
            }
            else
            {
                print("-> +")
                buffer.append(connPackets)
            }
        }
//        else
//        {
//            print("No complete connections to save.")
//        }
        
        print("-> @")
        var allowBlock = false
        if let cmdLineAllowBlock = maybeAllowBlock
        {
            allowBlock = cmdLineAllowBlock
        }
        else
        {
            guard let queueAllowBlock = allowBlockChannel.dequeue() else
            {
                return
            }
            allowBlock = queueAllowBlock
        }
        
        if buffer.count > 0
        {
            for (index, packet) in buffer.enumerated()
            {
                print("-> Saving complete connections. (\(index+1)/\(buffer.count)) --<-@")
                songLab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: packet)
                debug_addTrainPacketCount += 1
            }
        }
        
        if rawCaptured.count > 0
        {
            for (index, rawConnection) in rawCaptured.enumerated()
            {
                print("-> Saving complete raw connections. (\(index+1)/\(rawCaptured.count)) --<-@")
                songLab.AddRawTrainPacket(transport: transport, allowBlock: allowBlock, conn: rawConnection.value)
            }
        }
        
        // Usually we want both incoming and outgoingf packets
        // In the case where we know these are blocked connections
        // We want to record the data even when we have not received a response.
        // This is still a valid blocked case. We expect that some blocked connections will behave in this way.
        
        //If the connections in this map are labeled blocked by the user
        print("-> newAllowBlock is ", allowBlock)
        if allowBlock == false
        {
            print("-> Captured count is ", captured.count)
            if captured.count > 0
            {
                for (_, (_, connection)) in captured.enumerated()
                {
                    //print("Entering loop for saving incomplete connections. (\(index+1)/\(captured.count))")
                    // If this connection in the map is incomplete (only the incoming packet was captured) save it
                    // Check this because a complete struct (both incoming and outgoing packets are populated)
                    // will already be getting saved by the above for loop
                    if connection.Outgoing == nil
                    {
                        print("-> Saving incomplete connection.  --<-@")
                        songLab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connection)
                        debug_addTrainPacketCount += 1
                        debug_savedIncompletePacketCount += 1
                    }
                }
            }
        }
        
        
        
        print("-> total packet count = \(debug_packetCount)")
        print("-> port match packet count = \(debug_portMatchPacketsCount)")
        print("-> payload packet count = \(debug_payloadPacketsCount)")
        print("-> payload recorded packet count = \(debug_recordedPacketsCount)")
        print("-> payload recorded complete packet count = \(debug_recordedCompletePacketsCount)")
        print("-> add train packet count = \(debug_addTrainPacketCount)")
        print("-> add saved incomplete packet count = \(debug_savedIncompletePacketCount)")
        print("--> We are done saving things to the database. Bye now!\n")
        exit(1)
    }
    
    func finishCapture()
    {
        self.recording = false
        if self.allowBlockChannel.isEmpty
        {
            self.allowBlockChannel.enqueue(true)
        }
        self.saveCaptured()
    }
}

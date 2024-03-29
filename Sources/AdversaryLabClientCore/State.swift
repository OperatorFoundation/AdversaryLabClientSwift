//
//  State.swift
//  
//
//  Created by Dr. Brandon Wiley on 5/4/20.
//

import Foundation

import Chord
import Datable
import InternetProtocols
import PacketStream
import SwiftQueue
import ZIPFoundation

#if os(macOS)
import PacketCaptureBPF
#elseif os(Linux)
import PacketCaptureLibpcap
#endif

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

let packetsKey: String = "Packets"

import Foundation
import InternetProtocols

var validPCAPfile: String = ""
var sourceReadFromFile: Bool = false //false = read from interface (default), true = read from file

public struct ConnectionPackets: Codable
{
    //first incoming/outgoing relative to server
    var Incoming: Packet
    var Outgoing: Packet?
}

public struct RawConnectionPackets: Codable
{
    //all packets
    var Incoming: [Packet] = []
    var Outgoing: [Packet] = []
}

public class State
{
    var maybeAllowBlock: Bool? = nil
    let allowBlockChannel: Queue<Bool> = Queue<Bool>()
    var captured: [Connection:ConnectionPackets] = [:]
    var rawCaptured: [Connection:RawConnectionPackets] = [:]
    let packetChannel = Queue<Packet>()
    let recordable = Queue<ConnectionPackets>()
    var debugPrints: Bool
    var debug_packetCount = 0
    var debug_portMatchPacketsCount = 0
    var debug_payloadPacketsCount = 0
    var debug_recordedRawPacketsCount = 0
    var debug_recordedPacketsCount = 0
    var debug_recordedCompletePacketsCount = 0
    var debug_addTrainPacketCount = 0
    var debug_savedIncompletePacketCount = 0
    var songLab: SongClient
    let transport: String
    let port: UInt16
    var recording: Bool
    let signalQueue = DispatchQueue(label: "signal")
    var source: PacketStream?
    var repeatingTask: RepeatingTask? = nil
    
    public init(transport: String, port: UInt16, songClient: SongClient, debugPrints: Bool = false)
    {
        self.transport = transport
        self.port = port
        songLab = songClient
        self.recording = false
        self.debugPrints = debugPrints
    }    
    
    public func startCapture(_ interface: String?) -> Bool
    {
        let deviceName: String
        
        if let name = interface
        {
            // User has provided the interface name, use that
            deviceName = name
        }
        else
        {
            // Try to guess the correct interface
            // If we can't then we cannot proceed
            guard let name = InterfaceController.guessUserInterface()
            else
            {
                print("-> Unable to start capture: an interface name was not provided, and we were unable to find one to try.")
                return false
            }
            
            deviceName = name
        }
        
        self.recording = true

        let packetChannel = Queue<Packet>()
        switch sourceReadFromFile
        {
            #if os(Linux)
            case true : //read from pcap file
                guard let packetSource = PcapFile(path: validPCAPfile) else
                {
                    print("-> Unable to start capture: ")
                    print("-> Error opening file")
                    return false
                }

                do
                {
                    try packetSource.startCapture()
                }
                catch
                {
                    print("-> Unable to start capture: \(error)")
                    return false
                }

                self.source = packetSource
                self.readPackets(dest: packetChannel, port: self.port)
            #endif

            default : //read from network interface
                
                guard let packetSource = CaptureDevice(interface: deviceName) else
                {
                    print("-> Error getting capture device with interface \(deviceName). Packets will not be recorded.")
                    return false
                }

                do
                {
                    try packetSource.startCapture()
                }
                catch
                {
                    print("-> Error starting capture device: \(error)")
                    return false
                }

                self.source = packetSource
                self.readPackets(dest: packetChannel, port: self.port)
        }
        
        return true
    }

    public func stopCapture()
    {
        self.repeatingTask?.cancel()
        self.repeatingTask?.wait()
        cleanup()
    }
    
    func cleanup()
    {
        do
        {
            if let source = self.source
            {
                try source.stopCapture()
            }
        }
        catch let stopError
        {
            print("Stop capture error: \(stopError)")
        }

        if self.allowBlockChannel.isEmpty
        {
            self.allowBlockChannel.enqueue(true)
        }

        self.saveCaptured()
    }

    func readPackets(dest: Queue<Packet>, port: UInt16)
    {
        print("-> reading packets")
        
        repeatingTask = RepeatingTask
        {
            guard let source = self.source else {return false}
            guard let result = source.nextCaptureResult() else {return false}
            
            for packet in result.packets
            {
                if packet.payload.count > 0
                {
                    self.debug_packetCount += 1

                    // DEBUG: Print the payload
                    if (self.debugPrints)
                    {
                        print("-> Raw packet payload: ")
                        _ = printDataBytes(bytes: packet.payload, hexDumpFormat: true, seperator: "", decimal: false)
                        
                    }
                    
                    // parse the packet
                    let thisPacket = Packet(rawBytes: packet.payload, timestamp: packet.timestamp, debugPrints: self.debugPrints)

                    // capture the tcp packet
                    if thisPacket.tcp != nil //capture tcp packet
                    {
                        self.capturePort(thisPacket, port)
                    }
                    else // FIXME: THIS IS A WORKAROUND FOR WIRELESS
                    {
                        if let ethernetPacket = thisPacket.ethernet
                        {
                            let firstByte = ethernetPacket.payload[0]
                            if (firstByte == 0x45)
                            {
                                let wirelessPacket = Packet(ipv4Bytes: ethernetPacket.payload, timestamp: packet.timestamp, debugPrints: self.debugPrints)
                                if wirelessPacket.tcp != nil
                                {
                                    self.capturePort(wirelessPacket, port)
                                }
                            }
                        }
                    }
                }
            }
            
            return true
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
        guard let conn = NewConnection(packet: packet) else { return }
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
        guard let TCPsegment = packet.tcp else { return }
        let incoming = TCPsegment.destinationPort == port
        
        var connPackets = rawCaptured[conn, default: RawConnectionPackets()]
        
        if incoming
        {
            connPackets.Incoming.append(packet)
            rawCaptured[conn] = connPackets
        }
        else
        {
            connPackets.Outgoing.append(packet)
            rawCaptured[conn] = connPackets
        }
        
        debug_recordedRawPacketsCount += 1
    }
    
    func recordPacket(_ packet: Packet, _ port: UInt16)
    {
        guard let conn = NewConnection(packet: packet) else
        {
            print("-> recordPacket() failed to init a NewConnection with \(packet)")
            return
        }
        
        guard let TCPsegment = packet.tcp else
        {
            print("-> recordPacket() failed because packet.tcp is nil. \(packet)")
            return
        }
        
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
        print("-> Do we have any packets to save? \(!recordable.isEmpty)")
        var buffer: [ConnectionPackets] = []
        
        // Get the allowed or blocked designation for this packet
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
        
        // Save raw packets
        if rawCaptured.count > 0
        {
            for (index, rawConnection) in rawCaptured.enumerated()
            {
                print("-> Saving raw connections. (\(index+1)/\(rawCaptured.count)) --<-@")
                songLab.AddRawTrainPacket(transport: transport, allowBlock: allowBlock, conn: rawConnection.value)
            }
        }
        
        print("-> @")
        // Save complete connections
        while !recordable.isEmpty
        {
            print("-> Saving complete connections")
            guard let connPackets = recordable.dequeue() else
            {
                print("-> .")
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

        if buffer.count > 0
        {
            for (index, packet) in buffer.enumerated()
            {
                print("-> Saving complete connections. (\(index+1)/\(buffer.count)) --<-@")
                songLab.AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: packet)
                debug_addTrainPacketCount += 1
            }
        }
        
        // Usually we want both incoming and outgoing packets
        // In the case where we know these are blocked connections
        // We want to record the data even when we have not received a response.
        // This is still a valid blocked case. We expect that some blocked connections will behave in this way.
        
        //If the connections in this map are blocked
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
                        
        let fileManager = FileManager()
        let destinationURL = URL(fileURLWithPath: "adversary_data.zip")
        
        if fileManager.fileExists(atPath: databaseDirectory.path)
        {
            print("-> Zipping adversary_data ......")
            
            if fileManager.fileExists(atPath: destinationURL.path) {
                do
                {
                    print("-> Deleting existing adversary_data.zip")
                    try fileManager.removeItem(atPath: destinationURL.path)
                }
                catch let error as NSError
                {
                    print("-> Couldn't delete existing zip archive of adversary_data: \(error)")
                }
            }
            
            do
            {
                #if os(macOS)
                setbuf(__stdoutp, nil)
                let progress = Progress()
                let _ = ZIPProgressObserver(object: progress)
                print("[                    ]", terminator: "")
                try fileManager.zipItem(at: databaseDirectory, to: destinationURL, progress: progress)
                #else
                try fileManager.zipItem(at: databaseDirectory, to: destinationURL)
                #endif
            }
            catch
            {
                print("-> Failed to zip \(databaseDirectory.path) to \(destinationURL.path).")
                print("-> Zip error:\(error)")
            }
            
            if debug_addTrainPacketCount > 0
            {
                print("-> We saved \(debug_addTrainPacketCount) packets.")
                if debug_savedIncompletePacketCount > 0
                {
                    print("->\(debug_savedIncompletePacketCount) were incomplete packets.")
                }
            }
            else
            {
                print("-> There were no packets to save this time!")
                print("-> DEBUG ONLY:")
                print("-> total packet count = \(debug_packetCount)")
                print("-> port match packet count = \(debug_portMatchPacketsCount)")
                print("-> payload packet count = \(debug_payloadPacketsCount)")
                print("-> recorded raw packet count = \(debug_recordedRawPacketsCount)")
                print("-> payload recorded packet count = \(debug_recordedPacketsCount)")
                print("-> payload recorded complete packet count = \(debug_recordedCompletePacketsCount)")
                print("-> add train packet count = \(debug_addTrainPacketCount)")
                print("-> add saved incomplete packet count = \(debug_savedIncompletePacketCount)")
                print("-> END DEBUG")
            }
            
            print("\n--> We are done zipping the database. Bye Now!\n")
        }
        else
        {
            print("-> Failed to zip the database, no file was found at \(databaseDirectory.path)")
        }
    }
}


#if os(macOS)
class ZIPProgressObserver: NSObject
{
    @objc var objectToObserve: Progress
    var observation: NSKeyValueObservation?
    var displayedCount = 0
    
    init(object: Progress) {
        objectToObserve = object
        super.init()
        
        observation = observe(\.objectToObserve.fractionCompleted, options: [.old, .new])
        {
            object, change in
            
            //[==============================] //30
            //[====================] //20
            let value = Int((change.newValue! * 100)/5)
            //print("\r", terminator: "\n")
            var progressString = "["
            if value > self.displayedCount
            {
                self.displayedCount = value
                
                
                for _ in 0..<self.displayedCount
                {
                    progressString += "="
                }
                for _ in 0..<(20-self.displayedCount)
                {
                    progressString += " "
                    
                }
                //print("a", terminator: "\n")
                progressString += "]"
               
                print( "\r" + progressString, terminator: "")
                
            }
            //print("progress changed from: \(change.oldValue!), updated to: \(change.newValue!)")
        }
    }
}
#endif

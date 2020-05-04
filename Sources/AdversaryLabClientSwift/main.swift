import Foundation

import SwiftPCAP
import SwiftQueue
import AdversaryLabClient


//fix argument parsing to include reading from file
//hack for reading from pcap file without parsing command line args...
var filePath: String = ""
let sourceReadFromFile: UInt8 = 0 //0= read from interface (default), 1=read from file
let pcapFileName: String = "PCAPfiles/tcp-ethereal-file1.trace.pcap" //path starting from project base directory
//end hack


//import Rethink

struct Connection: Hashable
{
    let small: UInt16
    let big: UInt16
}

func NewConnection(packet: TCP) -> Connection
{
    if packet.sourcePort < packet.destinationPort
    {
        return Connection(small: packet.sourcePort, big: packet.destinationPort)
    }
    else
    {
        return Connection(small: packet.destinationPort, big: packet.sourcePort)
    }
}

extension Connection
{
    func CheckPort(port: UInt16) -> Bool
    {
        return self.small == port || self.big == port
    }
}









class State
{
    var maybeAllowBlock: Bool? = nil
    let allowBlockChannel: Queue<Bool> = Queue<Bool>()
    var captured: [Connection:ConnectionPackets] = [:]
    var rawCaptured: [Connection:RawConnectionPackets] = [:]
    let packetChannel: Queue<TCP> = Queue<TCP>()
    let recordable: Queue<ConnectionPackets> = Queue<ConnectionPackets>()
    let queue: DispatchQueue = DispatchQueue.init(label: "AdversaryLab")
    var debug_packetCount = 0
    
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

    func capture(transport: String, port: String)
    {
        print("-> Launching server...")

        guard let lab = Connect() else
        {
            print("Connect error!")
            return
        }

        print("Connected.")
        
        #if os(OSX)
        let deviceName: String = "en0"
        #elseif os(Linux)
        let deviceName: String = "ens18"
        #else
        let deviceName: String = "eth0"
        #endif


        let packetChannel = Queue<TCP>()
        switch sourceReadFromFile {
            case 1 :
                guard let packetSource = try? SwiftPCAP.Offline(path: filePath) else
                {
                    print("-> Error opening file")
                    return
                }
                self.queue.async
                {
                    print("readPkts file")
                    self.readPackets(source: packetSource, dest: packetChannel)
                }
            
            default :
                guard let packetSource = try? SwiftPCAP.Live(interface: deviceName) else
                {
                    print("-> Error opening network device")
                    return
                }
                self.queue.async
                {
                    print("readPkts interface")
                    self.readPackets(source: packetSource, dest: packetChannel)
                }
            
        }

        
        
        
        guard let selectedPort = UInt16(port) else
        {
            print("selPort")
            return
        }

        queue.async
        {
            print("capPort")
            self.capturePort(selectedPort)
        }
        print("saveCaptured")
        saveCaptured(lab, transport)
        
        
        
    }

    func readPackets(source: SwiftPCAP.Base, dest: Queue<TCP>)
    {
        while true
        {
            let bytes = source.nextPacket()
            let timestampMicrosecs = Date().timeIntervalSince1970 //* 1e6
            //let currentPacket = Packet()
            
            if bytes.count == 0
            {
                print("\n\n_", terminator: "")
                
                if sourceReadFromFile == 1 { //reading from file and have reached the end of file
                    print("\n\nEnd of PCAP file reached\n")
                    return
                }
                
                sleep(1)
            }
            else
            {
                
                
                debug_packetCount += 1
                print("\n\nP# \(debug_packetCount) - bytes \(bytes.count):")
                print("timestamp: " + String(format: "%F", timestampMicrosecs))
                var count = 0
                for byte in bytes{
                    print(String(format: "%02x", byte), terminator: " ")
                    count += 1
                    if count % 8 == 0{
                        print(" ", terminator: "")
                    }
                    if count % 16 == 0{
                        print("")
                    }
                }
                print("\n")
                
                if let epacket = Ethernet(data: Data(bytes)){
                    print("\nethernet parse success\n")
                    
                    switch epacket.type {
                    case .IPv4:
                        if let ippacket = IPv4(data: epacket.payload){
                            print("\nIP parse success!\n")
                            
                            if ippacket.protocolNumber == 0x06 {
                                if let tcpSegment = TCP(data: ippacket.payload){
                                     print("\nTCP parse success!\n")
                                     
                                }else{
                                     print("\nno parse TCP\n")
                                 }
                            }
                            
                            if ippacket.protocolNumber == 0x11 {
                                if let udpSegment = UDP(data: ippacket.payload){
                                     print("\nUDP parse success!\n")
                                     
                                }else{
                                     print("\nno parse UDP\n")
                                 }
                            }
                            
                            
                            
                        } else {
                            print("\nno parse IPv4\n")
                        }
                        
                    default:
                        print("^^^^not IPv4 packet^^^^")
                        print("Ethernet Packet Type: \(epacket.type.rawValue)")
                    }


                }else {
                    print("\nethernet parse FAIL\n")
                }
                
//                if let packet = TCP(data: Data(bytes))
//                {
//                    dest.enqueue(packet)
//
//                }
            }
        }
    }

    func capturePort(_ port: UInt16)
    {
        print("-> Capturing port \(port)")

        var count = UInt16(captured.count)

        while allowBlockChannel.isEmpty
        {
            if let packet = packetChannel.dequeue()
            {
                let conn = NewConnection(packet: packet)
                guard conn.CheckPort(port: port) else
                {
                    continue
                }

                recordRawPacket(packet, port)

                if packet.payload != nil
                {
                    recordPacket(packet, port)

                    let newCount = UInt16(captured.count)
                    if newCount > count
                    {
                        count = newCount
                    }
                }
            }
        }
    }

    func recordRawPacket(_ packet: TCP, _ port: UInt16)
    {
        print("Entered recordRawPacket")
        let conn = NewConnection(packet: packet)
        let incoming = packet.destinationPort == port
        var connPackets = rawCaptured[conn, default: RawConnectionPackets()]

        if incoming {
            connPackets.Incoming.append(packet)
            rawCaptured[conn] = connPackets
        } else {
            connPackets.Outgoing.append(packet)
            rawCaptured[conn] = connPackets
        }
    }

    func recordPacket(_ packet: TCP, _ port: UInt16)
    {
        print("recPkt")
        let conn = NewConnection(packet: packet)
        let incoming = packet.destinationPort == port
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

    func saveCaptured(_ lab: Client, _ transport: String)
    {
        print("-> Saving captured raw connection packets... ")
        var buffer: [ConnectionPackets] = []
        var count = 0
        
        while allowBlockChannel.isEmpty
        {


            if !recordable.isEmpty
            {
                print("!")
                guard let connPackets = recordable.dequeue() else
                {
                    print(".")
                    continue
                }
                
                if maybeAllowBlock == nil
                {
                    print("+")
                    buffer.append(connPackets)
                }
                else
                {
                    print("**")
                    guard let allowBlock = maybeAllowBlock else
                    {
                        print("-")
                        continue
                    }
                    
                    print("*")
                    AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connPackets)
                }
            }
        }
        
        print("@")
        guard let allowBlock = allowBlockChannel.dequeue() else
        {
            return
        }
        
        for packet in buffer
        {
            print("-> Saving complete connections. --<-@")
            AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: packet)
        }
        
        for (_, rawConnection) in rawCaptured
        {
            print("-> Saving complete raw connections. --<-@")
            AddRawTrainPacket(transport: transport, allowBlock: allowBlock, conn: rawConnection)
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
                    AddTrainPacket(transport: transport, allowBlock: allowBlock, conn: connection)
                }
            }
        }

        print("--> We are done saving things to the database. Bye now!\n")
        exit(1)
    }
    
    func AddTrainPacket(transport: String, allowBlock: Bool, conn: ConnectionPackets)
    {
        print("addtrainpk")
    }
    
    func AddRawTrainPacket(transport: String, allowBlock: Bool, conn: RawConnectionPackets)
    {
        print("addrawtrainpk")
    }
}













func main()
{
    do {
        print("Delaying to allow debugger to attach to process...")
        sleep(1)
    }
    print("-> Adversary Lab Client is running...Now in Swift!")
    let state = State()

    //https://swift.org/blog/argument-parser/
    //https://github.com/apple/swift-argument-parser/blob/master/Documentation/01%20Getting%20Started.md
    //https://developer.apple.com/documentation/swift/commandline

    
    //hack for running pcap files located in the project's directory, makes assumptions about the  DerrivedData path...
    if sourceReadFromFile == 1 {
        let basePath = CommandLine.arguments[0] //path of executable
        var basePathURL = URL(fileURLWithPath: basePath)
        for i in 1...6 { //cd .. to project directory from DerrivedData build directory
           basePathURL.deleteLastPathComponent()
        }
        basePathURL.appendPathComponent(pcapFileName)
        filePath = basePathURL.path

        print("Reading Packets from file:")
        print(filePath)
    }
    //end hack
    
    
    
    
//  //orig code:
    if CommandLine.arguments.count < 3
    {
        usage()
        return
    }

    let transport = CommandLine.arguments[1]
    let port = CommandLine.arguments[2]

    if CommandLine.arguments.count == 3
    {
        // Buffering Mode
        // The user has not yet indicated which category this data belongs to.
        // Buffer the data until the user enters 'allowed' or 'blocked'.
        state.queue.async
        {
            state.listenForDataCategory()
        }
        print("3 args")
        state.capture(transport: transport, port: port)
    }
    else if CommandLine.arguments.count == 4
    {
        // Streaming Mode
        // The user has indicated how this data should be categorized.
        // Save the data as we go using the indicated category.
        if CommandLine.arguments[3] == "allow"
        {
            state.maybeAllowBlock = true
        }
        else if CommandLine.arguments[3] == "block"
        {
            state.maybeAllowBlock = false
        }
        else
        {
            usage()
            return
        }
        print("4 args")
        state.capture(transport: transport, port: port)
    }
    else
    {
        usage()
        return
    }
}

func usage()
{
    //dest ip filter, AdversaryLabClient <transport> <port> [ip address] [protocol]
    /*
     <--interface INTERFACE_NAME > //read packets from a live interface eg eth0, en0, etc
     <--transport, -t TRANSPORT >  //only include TRANSPORT packets
     <--port PORT_NUMBER >           //only include packets on PORT_NUMBER
     [--read-file -r FILE_PATH]   //read packets from a pcap file, if this is specified then interface option is ignored
     [--list-interfaces] //list available interfaces, all other options are ignored. can SCNetworkConfiguration be used?
     [--categorize-as -c BLOCK | ALLOW ] //if omitted buffering mode is assumed otherwise is categorized as specified
     [--ip-address -i IPV4_ADDRESS ] //only include traffic to/from IPV4_ADDRESS
     [--protocol ?PROTOCOL??? ] //only include PROTOCOL

     
     
     */
    print("-> AdversaryLabClient <transport> <port> [protocol]")
    print("-> Example: AdversaryLabClient HTTP 80 allow")
    print("-> Example: AdversaryLabClient HTTPS 443 block")
    print("-> Example: AdversaryLabClient HTTP 80")
    print("-> Example: AdversaryLabClient HTTPS 443")
    print()
}

main()

import Foundation

import SwiftPCAP
import SwiftQueue
import AdversaryLabClient
import Dispatch

//fix argument parsing to include reading from file
//hack for reading from pcap file without parsing command line args...
var filePath: String = ""
let sourceReadFromFile: UInt8 = 0 //0= read from interface (default), 1=read from file
let pcapFileName: String = "PCAPfiles/tcp-ethereal-file1.trace.pcap" //path starting from project base directory
//end hack

import Rethink

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

func main()
{
    print("Delaying to allow debugger to attach to process...")
    print("1 second pause to allow debugger to attach....")
    sleep(1)
    
    print("-> Adversary Lab Client is running...Now in Swift!")
    
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
    
    if CommandLine.arguments.count < 3
    {
        usage()
        return
    }
    
    let transport = CommandLine.arguments[1]
    let port = CommandLine.arguments[2]

    guard let selectedPort = UInt16(port) else
    {
        print("selPort")
        return
    }
    
    if CommandLine.arguments.count == 3
    {
        print("3 args")
        
        Connect
        {
            maybeClient in
            
            guard let client = maybeClient else
            {
                print("Could not connect to RethinkDB")
                return
            }
          
            let state = startCapture(transport: transport, port: selectedPort, client: client)
            
            // Buffering Mode
            // The user has not yet indicated which category this data belongs to.
            // Buffer the data until the user enters 'allowed' or 'blocked'.
            state.queue.async
            {
                    state.listenForDataCategory()
            }
        }
    }
    else if CommandLine.arguments.count == 4
    {
        let allowBlock: Bool
        
        // Streaming Mode
        // The user has indicated how this data should be categorized.
        // Save the data as we go using the indicated category.
        if CommandLine.arguments[3] == "allow"
        {
            allowBlock = true
        }
        else if CommandLine.arguments[3] == "block"
        {
            allowBlock = false
        }
        else
        {
            usage()
            return
        }
        
        print("4 args")
        
        Connect
        {
            maybeClient in
            
            guard let client = maybeClient else
            {
                print("Could not connect to RethinkDB")
                return
            }
          
            let state = startCapture(transport: transport, port: selectedPort, client: client)
            state.maybeAllowBlock = allowBlock
        }
    }
    else
    {
        usage()
        return
    }
}

func startCapture(transport: String, port: UInt16, client: Client) -> State
{
    let state = State(transport: transport, port: port, client: client)
    
    signal(SIGINT, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    source.setEventHandler
    {
        print("event handler happened")
        print("saveCaptured")
        state.recording = false
        if state.allowBlockChannel.isEmpty
        {
            state.allowBlockChannel.enqueue(true)
        }
        state.saveCaptured()
        exit(0)
    }
    source.resume()
    
    state.capture()
    
    return state
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

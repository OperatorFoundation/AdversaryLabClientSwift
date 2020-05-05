import Foundation

import SwiftPCAP
import SwiftQueue
import AdversaryLabClient
import Dispatch
import ArgumentParser

var validPCAPfile: String = ""
var sourceReadFromFile: Bool = false //false = read from interface (default), true = read from file

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



struct AdversaryLabClientSwift: ParsableCommand {
    
    //transport, port, allowBlock (optional), path to pcap file (optional)
    //allow block is required if pcap file is used - currently parameters specified by argument position
    //fix, how to tell user that --help ro -? prints full usage info and help on the command
    
    @Argument(help: "The transport to capture. examples: HTTP, HTTPS, FTP, etc.") //fix with better examples
    var transport: String
    
    @Argument(help: "The port to capture, valid range between 1 and 65535. examples: 80, 443, 21, etc") //fix with better examples
    var port: Int
    
    @Argument(help: "Optional parameter: categorize the packets as [allow] or [block], if omitted user clasifies packets at end of capture by typing \"allow\" to classify as allowed packets, or \"block\" to clasify as blocked packets. This is a required parameter if reading from pcap file.")
    var allowOrBlock: String?
    
    @Argument(help: "Optional parameter: path to pcap file to read packets from instead of a physical interface. example: /user/alice/capture.pcap")
    var pcapFile: String?

    func validate() throws {
        
        guard self.transport == "HTTP" || self.transport == "HTTPS" else {
            throw ValidationError("'<transport>' must be either 'HTTP' or 'HTTPS'. Use --help for more info.")
        }
        
        guard self.port > 0 && self.port <= 65535 else {
            throw ValidationError("'<port>' must be between 1 and 65535. Use --help for more info.")
        }
        
        if self.allowOrBlock != nil {
            guard self.allowOrBlock == "allow" || self.allowOrBlock == "block" else {
                throw ValidationError("'<allowOrBlock>' must be either 'allow' or 'block'. Use --help for more info.")
            }
        }
        
        if self.pcapFile != nil
        {
            let pcapFilePath = self.pcapFile! //above if statment prevents unwrapping a nil

            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: pcapFilePath)
            {
                //fix, is this the best way to test for a vaid pcap file?
                //fix, will the memory for packetSource be released, doesn't seem to be a function of SwiftPCAP to release memory or close the capture
                guard let packetSource = try? SwiftPCAP.Offline(path: pcapFilePath) else
                {
                    throw ValidationError("error opening pcap file, file seems to be invalid. Use --help for more info.")
                }
                print("valid pcap file exists!")
                sourceReadFromFile = true
                validPCAPfile = pcapFilePath
            }
            else
            {
                throw ValidationError("pcap file not found! use full path to file. Use --help for more info.")
            }
        }

    }
    
    
    func run() throws {
        print("Delaying 1 second to allow debugger to attach to process...")
        sleep(1)
        print("-> Adversary Lab Client is running...Now in Swift!")
        
        //https://swift.org/blog/argument-parser/
        //https://github.com/apple/swift-argument-parser/blob/master/Documentation/01%20Getting%20Started.md
        //https://developer.apple.com/documentation/swift/commandline
        

        let selectedPort = UInt16(self.port)
        
        if allowOrBlock == nil
        {
            print("buffering mode - user to classify packets at end of capture")
            Connect
               {
                   maybeClient in
                   
                   guard let client = maybeClient else
                   {
                       print("Could not connect to RethinkDB")
                       return
                   }
                 
                let state = startCapture(transport: self.transport, port: selectedPort, client: client)
                   
                   // Buffering Mode
                   // The user has not yet indicated which category this data belongs to.
                   // Buffer the data until the user enters 'allowed' or 'blocked'.
                   state.queue.async
                   {
                           state.listenForDataCategory()
                   }
               }
               dispatchMain()
        } else {
            
            var allowBlock: Bool
            // Streaming Mode
            // The user has indicated how this data should be categorized.
            // Save the data as we go using the indicated category.
            
            if self.allowOrBlock == "allow"
            {
                allowBlock = true
            }
            else if self.allowOrBlock == "block"
            {
                allowBlock = false
            }
            else
            {
                usage()
                return
            }

            guard let ab = self.allowOrBlock else { return }
            print("streaming mode - packets will be classified as \(ab)ed")
            
            Connect
            {
                maybeClient in
                
                guard let client = maybeClient else
                {
                    print("Could not connect to RethinkDB")
                    return
                }
              
                let state = startCapture(transport: self.transport, port: selectedPort, client: client)
                state.maybeAllowBlock = allowBlock
            }
            dispatchMain()
        }
    }
}

AdversaryLabClientSwift.main()



func startCapture(transport: String, port: UInt16, client: Client) -> State
{
    let state = State(transport: transport, port: port, client: client)
    
    // Ignore default signal handling, which is killing the app
    signal(SIGINT, SIG_IGN)
    
    let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    source.setEventHandler
    {
        print("event handler happened")
        
        // Restore default signal handling, which means killing the app
        signal(SIGINT, SIG_DFL)
        
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



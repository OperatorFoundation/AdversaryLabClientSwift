import Foundation
import SwiftQueue
import Dispatch
import ArgumentParser
import AdversaryLabClientCore

#if os(Linux)
import PacketCaptureLibpcap
#else
import PacketCaptureBPF
#endif


var validPCAPfile: String = ""
var sourceReadFromFile: Bool = false //false = read from interface (default), true = read from file

struct AdversaryLabClientSwift: ParsableCommand
{
    //https://swift.org/blog/argument-parser/
    //https://github.com/apple/swift-argument-parser/blob/master/Documentation/01%20Getting%20Started.md
    //Old way of handling CLI options https://developer.apple.com/documentation/swift/commandline
    
    //transport, port, allowBlock (optional), path to pcap file (optional)
    //allowBlock is required if pcap file is used - currently parameters specified by argument position
    //   parameters should ultimately use flags
    //dest ip filter, AdversaryLabClient <transport> <port> [ip address] [protocol]
    //flag to save partials
    
    /*
     Future:
     Example of Flags version
     <--interface INTERFACE_NAME > //read packets from a live interface eg eth0, en0, etc
     <--transport, -t TRANSPORT >  //name of transport captured
     <--port PORT_NUMBER >           //only include packets on PORT_NUMBER
     [--read-file -r FILE_PATH]   //read packets from a pcap file, if this is specified then interface option is ignored
     [--list-interfaces] //list available interfaces, all other options are ignored. can SCNetworkConfiguration be used?
     [--categorize-as -c BLOCK | ALLOW ] //if omitted buffering mode is assumed otherwise is categorized as specified
     [--ip-address -i IPV4_ADDRESS ] //only include traffic to/from IPV4_ADDRESS
     [--protocol ?PROTOCOL??? ] //only include PROTOCOL
     */
    
    static var configuration = CommandConfiguration(
        abstract: "Packet capture for Adversary Lab.",
        discussion: """
            Adversary Lab Client captures packets meeting certain critera specified by the user and classifies the traffic as allowed or blocked for use in Adversary Lab. \nAdversary Lab is a service that analyzes captured network traffic to extract statistical properties. Using this analysis, filtering rules can be synthesized to block sampled traffic. The purpose of this service is to help application developers create applications which are more resistant to network filtering attacks. https://OperatorFoundation.org/
            """)
    
    @Argument(help: "The transport to capture. examples: HTTP, HTTPS, FTP, etc. This is just a name for the captured transport.")
    var transport: String
    
    @Argument(help: "The port to capture, valid range between 1 and 65535. examples: 80, 443, 21, etc") //fix with better examples
    var port: Int
    
    @Argument(help: "Optional parameter: categorize the packets as [allow] or [block], if omitted user clasifies packets at end of capture by typing \"allow\" to classify as allowed packets, or \"block\" to clasify as blocked packets. This is a required parameter if reading from pcap file.")
    var allowOrBlock: String?

    #if os(Linux)
    @Argument(help: "Optional parameter: path to pcap file to read packets from instead of a physical interface. example: /home/alice/packet_capture.pcap")
    var pcapFile: String?
    #endif
    
    func validate() throws
    {
        guard self.port > 0 && self.port <= 65535 else
        {
            throw ValidationError("'<port>' must be between 1 and 65535. Use --help for more info.")
        }
        
        if self.allowOrBlock != nil
        {
            guard self.allowOrBlock == "allow" || self.allowOrBlock == "block" else
            {
                throw ValidationError("'<allowOrBlock>' must be either 'allow' or 'block'. Use --help for more info.")
            }
        }

        #if os(Linux)
        if self.pcapFile != nil
        {
            let pcapFilePath = self.pcapFile! //above if statment prevents unwrapping a nil
            let fileManager = FileManager.default
            
            if fileManager.fileExists(atPath: pcapFilePath)
            {
                //fix, is this the best way to test for a vaid pcap file? Is checking for magic bytes better? https://wiki.wireshark.org/Development/LibpcapFileFormat
                //fix, will the memory for packetSource be released, doesn't seem to be a function of SwiftPCAP to release memory or close the capture
                guard let _ = PcapFile(path: pcapFilePath) else
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
        #endif
    }
    
    func run() throws
    {
        print("Delaying 1 second to allow debugger to attach to process...")
        print("tip: use --help or -h to print detailed usage info and help")
        sleep(1)
        print("-> Adversary Lab Client is running...Now in Swift!")
        
        let selectedPort = UInt16(self.port)
        
        if allowOrBlock == nil
        {
            print("buffering mode - user to classify packets at end of capture")

            DispatchQueue.main.async
            {
                if sourceReadFromFile
                {
                    startCapture(transport: self.transport, port: selectedPort, allowBlock: nil, pcapFile: validPCAPfile)

                }
                else
                {
                    startCapture(transport: self.transport, port: selectedPort, allowBlock: nil)
                }
            }

            dispatchMain()
        }
        else
        {
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

            DispatchQueue.main.async
            {
                if sourceReadFromFile
                {
                    startCapture(transport: self.transport, port: selectedPort, allowBlock: allowBlock)
                }
                else
                {
                    startCapture(transport: self.transport, port: selectedPort, allowBlock: allowBlock, pcapFile: validPCAPfile)
                }
            }
            
            dispatchMain()
        }
    }
}

func usage()
{
    print("-> AdversaryLabClient <transport> <port> [protocol]")
    print("-> Example: AdversaryLabClient HTTP 80 allow")
    print("-> Example: AdversaryLabClient HTTPS 443 block")
    print("-> Example: AdversaryLabClient HTTP 80")
    print("-> Example: AdversaryLabClient HTTPS 443")
    print()
}

AdversaryLabClientSwift.main()

//
//  AdversaryLabClientCore.swift
//  
//
//  Created by Dr. Brandon Wiley on 12/21/20.
//

import Foundation
import InternetProtocols

var validPCAPfile: String = ""
var sourceReadFromFile: Bool = false //false = read from interface (default), true = read from file

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

public func startCapture(transport: String, port: UInt16, allowBlock: Bool?, pcapFile: String? = nil)
{
    if let pcap = pcapFile
    {
        validPCAPfile = pcap
        sourceReadFromFile = true
    }

    let songClient = SongClient()

    let state = State(transport: transport, port: port, songClient: songClient)

    // Ignore default signal handling, which is killing the app
    signal(SIGINT, SIG_IGN)

    let source = DispatchSource.makeSignalSource(signal: SIGINT, queue: state.signalQueue)
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

    if allowBlock == nil
    {
        // Buffering Mode
        // The user has not yet indicated which category this data belongs to.
        // Buffer the data until the user enters 'allowed' or 'blocked'.
        state.queue.async
        {
            state.listenForDataCategory()
        }
    }
    else
    {
        state.maybeAllowBlock = allowBlock
    }

    state.capture()
}

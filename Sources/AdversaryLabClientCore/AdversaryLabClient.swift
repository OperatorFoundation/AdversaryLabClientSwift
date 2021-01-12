//
//  AdversaryLabClient.swift
//  
//
//  Created by Dr. Brandon Wiley on 12/29/20.
//

import Foundation

public class AdversaryLabClient
{
    let state: State

    public init(transport: String, port: UInt16, allowBlock: Bool?, pcapFile: String? = nil)
    {
        if let pcap = pcapFile
        {
            validPCAPfile = pcap
            sourceReadFromFile = true
        }

        let songClient = SongClient()
        state = State(transport: transport, port: port, songClient: songClient)
        state.maybeAllowBlock = allowBlock
    }
    
    public func startRecording()
    {
        state.startCapture()
    }

    public func stopRecording(_ allowBlock: Bool)
    {
        if state.allowBlockChannel.isEmpty
        {
            state.allowBlockChannel.enqueue(allowBlock)
        }

        state.stopCapture()
    }

    public func saveCaptured()
    {
        state.saveCaptured()
    }
}

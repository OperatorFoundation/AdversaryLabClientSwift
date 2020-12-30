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

        state.capture()
    }

    public func stopRecording(_ allowBlock: Bool)
    {
        state.recording = false
        if state.allowBlockChannel.isEmpty
        {
            state.allowBlockChannel.enqueue(allowBlock)
        }
        state.saveCaptured()
    }

    public func saveCaptured()
    {
        state.saveCaptured()
    }
}

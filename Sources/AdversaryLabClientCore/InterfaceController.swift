//
//  Interface.swift
//  AdversaryLabClientCore
//
//  Created by Mafalda on 4/1/21.
//

import Foundation

import NetUtils

struct InterfaceController
{
    static func guessUserInterface() -> String?
    {
        var allInterfaces = Interface.allInterfaces()
        
        // Get interfaces sorted by name
        allInterfaces.sort(by: {
            (interfaceA, interfaceB) -> Bool in
            
            return interfaceA.name < interfaceB.name
        })
        
        print("\n -> You did not indicate a preferred interface. Printing all available interfaces.")
        for interface in allInterfaces { print("\(interface.name)")}
        
        // Return the first interface that begins with the letter e
        // Note: this is just a best guess based on what we understand to be a common scenario
        // The user should use the interface flag if they have something different
        guard let bestGuess = allInterfaces.firstIndex(where: { $0.name.hasPrefix("e") })
        else
        {
            print("\n -> We were unable to identify a likely interface name. Please try running the program again using the correct interface name.\n")
            return nil
        }
        
        print("\n -> We will try using the \(allInterfaces[bestGuess].name) interface. If Canary fails to capture data, it may be because this is not the correct interface. Please try running the program again using the correct interface name.\n")
        
        return allInterfaces[bestGuess].name
    }
}

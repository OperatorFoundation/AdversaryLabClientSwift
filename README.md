# The Operator Foundation

[Operator](https://operatorfoundation.org) makes useable tools to help people around the world with censorship, security, and privacy.

## Adversary Lab

Adversary Lab is a service that analyzes captured network traffic to extract statistical properties. Using this analysis, filtering rules can be synthesized to block sampled traffic.

The purpose of Adversary Lab is to give researchers and developers studying network filtering a way to understand how easy it is to block different protocols.
If you have an application that uses a custom protocol, Adversary Lab will demonstrate how a rule can be synthesized to systematically block all traffic using that protocol.
Similarly, if you have a network filtering circumvention tool, then Adversary Lab can synthesize a rule to block your tool.
This analysis can also be used to study tools that specifically attempt to defeat networking filtering, such as Pluggable Transports.

Adversary Lab analysis works by training a classifier on two observed data sets, the "allow" set and the "block" set.
For instance, a simulated adversary could allow HTTP, but block HTTPS. By training the system with HTTP and HTTPS data, it will generate a rule that distinguishes these two classes of traffic based on properties observed in the traffic.

## AdversaryLabClientSwift

AdversaryLabClient is a command line tool written in Swift which captures traffic and submits it to AdversaryLab for analysis.

#### Installation

Adversary Lab is written in the Swift programming language. To compile it you need
to install Swift 5.1 or higher:

<https://swift.org/getting-started/>


#### Running

##### All commands for the client must be run from the AdversaryLabClientSwift project directory

To use the client, Adversary Lab must already be running. See the [AdversaryLab documentation](https://github.com/OperatorFoundation/AdversaryLab) to set up and run AdversaryLab.

To interface with the AdversaryLab service, you need to use the command line client.

Run the command line client without argument to get usage information:

    ./.build/x86_64-apple-macosx/debug/AdversaryLabClientSwift

**Train a simulated adversary by capturing network traffic that is designated as either allowed or blocked:**

    sudo ./.build/x86_64-apple-macosx/debug/AdversaryLabClientSwift 80 allow

This will capture live traffic with a destination port of 80 and add it to the dataset as training for what traffic the adversary should allow.

We will also need to train the simulated adversary using captured network traffic that gives an example of what to block:

    sudo ./.build/x86_64-apple-macosx/debug/AdversaryLabClientSwift 443 block

This will capture live traffic with a destination port of 443 and add it to the "example" dataset as training for what traffic the adversary should block.

**Alternately you can capture network traffic first and assign the data as either allowed or blocked when you have are done capturing traffic:**

In this scenario you simply leave off the allow/block designation and only provide the port you would like Adversary Lab to listen on. Adversary lab will buffer your traffic until you type in either "allow" or "block". At which point it will stop recording and add it to the dataset based on your input.

For example:

    sudo ./.build/x86_64-apple-macosx/debug/AdversaryLabClientSwift 443

or

    sudo ./.build/x86_64-apple-macosx/debug/AdversaryLabClientSwift 80

Once the simulated adversary has both "allow" and "block" traffic, and has observed at least three connections from each type, it can synthesize blocking rules.


//
//  main.m
//  BlockComment-XPC
//
//  Created by Brad Howes on 4/16/17.
//  Copyright © 2017 Brad Howes. All rights reserved.
//

import Foundation

class ServiceDelegate : NSObject, NSXPCListenerDelegate {

    private let server = BlockComment_XPC()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: BlockComment_XPCProtocol.self)
        newConnection.exportedObject = server
        newConnection.resume()
        return true
    }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate;
listener.resume()

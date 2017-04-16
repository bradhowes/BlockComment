//
//  BlockCommentExtension.swift
//  BlockComment
//
//  Created by Brad Howes on 9/29/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import XcodeKit

public let xpcConnection = NSXPCConnection(machServiceName: "com.brhcode.BlockComment-XPC", options: [])

class BlockCommentExtension: NSObject, XCSourceEditorExtension {
    
    func extensionDidFinishLaunching() {
        xpcConnection.remoteObjectInterface = NSXPCInterface(with: BlockComment_XPCProtocol.self)
        xpcConnection.resume()
    }

    /*
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        // If your extension needs to return a collection of command definitions that differs from those in its Info.plist, implement this optional property getter.
        return []
    }
    */
    
}

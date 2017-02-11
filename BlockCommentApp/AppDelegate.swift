//
//  AppDelegate.swift
//  BlockComment
//
//  Created by Brad Howes on 9/29/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let alert = NSAlert(); alert.messageText = "Extension installed! Click OK to quit."
        alert.beginSheetModal(for: window) { _ in
            exit(0)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}


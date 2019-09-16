//
//  ViewController.swift
//  BlockCommentApp
//
//  Created by Brad Howes on 9/16/19.
//  Copyright © 2019 Brad Howes. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func openExtensions(_ sender: Any) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preferences")!
        NSWorkspace.shared.open(url)
    }
}


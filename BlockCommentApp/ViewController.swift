// Copyright © 2019 Brad Howes. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0).cgColor
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

    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.stop(sender)
    }
}

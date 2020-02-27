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

    func openExtensionWithScript() {
        let source = """
tell application "System Preferences"
    activate
    reveal anchor "Extensions" of pane id "com.apple.preferences.extensions"
end tell
"""
        let script = NSAppleScript(source: source)!
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        print("\(error?.description ?? "NA")")
    }

    @IBAction func openExtensions(_ sender: Any) {
        openExtensionWithScript()
        // let url = URL(string: "x-apple.systempreferences:com.apple.preferences")!
        // NSWorkspace.shared.open(url)
    }

    @IBAction func quitApp(_ sender: Any) {
        NSApplication.shared.stop(sender)
    }
}

// Copyright © 2019 Brad Howes. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0).cgColor
  }
  
  @IBAction func openExtensions(_ sender: Any) {
    // let url = URL(string: "x-apple.systempreferences:com.apple.preferences")!
    // NSWorkspace.shared.open(url)
    // NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Extensions.prefPane"))
    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences?extensionPointIdentifier=com.apple.dt.Xcode.extension.source-editor"
                               )!)
  }
  
  @IBAction func quitApp(_ sender: Any) {
    NSApplication.shared.stop(sender)
  }
}

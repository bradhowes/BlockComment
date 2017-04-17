

import Foundation

@objc class BlockComment_XPC: NSObject, BlockComment_XPCProtocol {
    func uppercase(_ string: String, withReply: (String)->()) {
        withReply(string.uppercased())
    }
}

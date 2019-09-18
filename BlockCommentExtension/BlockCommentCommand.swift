// Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import XcodeKit
import BlockCommentLibrary

final class BlockCommentCommand: NSObject, XCSourceEditorCommand {

    /**
     Perform an action in the BlockComment plugin.
    
     - parameter invocation: the action to perform
     - parameter completionHandler: the callback to invoke when finished performing the requested action
     */
    public func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        BlockComment.generate(from: invocation, completionHandler: completionHandler)
    }
}

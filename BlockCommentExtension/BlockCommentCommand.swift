// Copyright © 2016-2019 Brad Howes. All rights reserved.

import Foundation
import XcodeKit

final class BlockCommentCommand: NSObject, XCSourceEditorCommand {

    /**
     Perform an action in the BlockComment plugin.

     - parameter invocation: the action to perform
     - parameter completionHandler: the callback to invoke when finished performing the requested action
     */
    public func perform(with invocation: XCSourceEditorCommandInvocation,
                        completionHandler: @escaping (Error?) -> Void ) -> Void {

        let buffer = invocation.buffer
        let lines = buffer.lines

        let selections = buffer.selections
        let selection = selections.firstObject as! XCSourceTextRange

        // Use the *end* of any selection. That way user can highlight any previous comment and get a new one.
        // - TODO: validate that selected region is really a comment block.
        //
        var pos = selection.end.line
        var line = ""

        // Skip over any blank lines
        //
        while pos < lines.count {
            line = (lines[pos] as! String).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !line.isEmpty {
                break
            }
            pos += 1
        }

        let command = invocation.commandIdentifier
        let comment: [String] = {
            switch command {
            case "insertBlockComment": return parse(source: Source(lines: (lines as NSArray as! [String]),
                                                                   firstLine: pos))
            case "insertMarkComment": return ["// MARK: - "]
            default: return ["// *** Unknown command ***"]
            }
        }()

        if comment.count > 0 {

            // Replace current (first) selection with new block comment
            //
            invocation.buffer.lines.replaceObjects(in: NSMakeRange(selection.start.line,
                                                                   selection.end.line - selection.start.line + 1),
                                                   withObjectsFrom: comment)
        }

        completionHandler(nil)
    }
}

//
//  BlockCommentCommand.swift
//  BlockCommentCommand
//
//  Created by Brad Howes on 9/29/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import XcodeKit

class BlockComment: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {

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

        // Grab the indentation of the line
        //
        line = lines[pos] as! String
        let chars = line.unicodeScalars
        var cursor = chars.startIndex
        while CharacterSet.whitespaces.contains(chars[cursor]) {
            cursor = chars.index(after: cursor)
        }
        
        let indent = String(repeating: " ", count: chars.distance(from: chars.startIndex, to: cursor))
        let parser = Parser(lines: (lines as NSArray as! [String]), currentLine: pos, indent: indent)
        let command = invocation.commandIdentifier

        let comment: [String] = {
            switch command {
            case "insertBlockComment":
                return parser.makeBlockComment()
            case "insertMarkComment":
                return parser.makeMarkComment()
            default:
                return []
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

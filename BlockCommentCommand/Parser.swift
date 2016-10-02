//
//  Parser.swift
//
//  Created by Brad Howes on 9/30/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/**
 Main class for the Swift parser. Our parser is very dumb. It only exists to provide rudimentary information about what
 kind of block comment to emit, and perhaps some information about what is being commented on. For now, the only
 additional info pertains to func/init prototypes.
 */
public final class Parser {
    
    /**
     Represents a subsequence of Unicode scalar values found in a larger one.
     */
    internal struct Range : CustomStringConvertible {
        private static let nilText = String("")!
        private static let nilView = nilText.unicodeScalars
        
        /**
         The Unicode scalar sequence containing the subsequence
         */
        let view: String.UnicodeScalarView
        
        /**
         The start of the subsequence
         */
        let start: String.UnicodeScalarIndex
        
        /**
         The end of the subsequence - points to the first scalar after the subsequence
         */
        let end: String.UnicodeScalarIndex
        
        /**
         Return the length of the sequence
         */
        var length: Int {
            return view.distance(from: start, to: end)
        }
        
        /**
         Initialize an empty sequence
         */
        init() {
            self.view = Range.nilView
            self.start = self.view.startIndex
            self.end = start
        }
        
        /**
         Define a range of Unicode scalars in a given scalar view.
         - parameter view: the scalar view
         - parameter start: the start of the sequence
         - parameter end: the end of the sequence (last scalar + 1)
         */
        init(view: String.UnicodeScalarView, start: String.UnicodeScalarIndex, end: String.UnicodeScalarIndex) {
            self.view = view
            self.start = start
            self.end = end
        }
        
        /**
         Determine if the subsequence is empty
         - returns: true if so
         */
        func isEmpty() -> Bool {
            return self.start == self.end
        }
        
        /**
         Obtain a Swift String containing the subsequence
         */
        var description: String {
            return String(view[start..<end])
        }

        var first: UnicodeScalar {
            return view.first!
        }
    }
    
    /**
     Holds function argument information.
     */
    public struct ArgInfo {
        
        /**
         Required label for the argument when the function is invoked
         */
        let label: String
        
        /**
         Name of the argument inside of the function
         */
        let name: String
        
        /**
         Type of the argument
         */
        let type: String
        
        /**
         Initialize function argument definition
         
         - parameter label: optional label at call site
         - parameter name: argument name inside function code
         - parameter type: type specification for the argument
         */
        internal init(label: Range, name: Range, type: Range) {
            self.label = label.description
            self.name = name.description
            self.type = type.description
        }
    }

    /**
     Contains meta data associated with a func/init call.
     */
    public struct FuncMeta {
        let name: String
        let args: [ArgInfo]
        let returnType: String
        let canThrow: Bool

        /**
         Collect meta data for a func/init
         - parameter name: the name of the func/init
         - parameter args: the argument specifications for the func/init
         - parameter returnType: the return type (empty string if returns nil)
         - parameter canThrow: true if can throw an error
         */
        internal init(name: String, args: [ArgInfo], returnType: String, canThrow: Bool) {
            self.name = name
            self.args = args
            self.returnType = returnType
            self.canThrow = canThrow
        }
    }

    /** 
     Contains meta data associated with type (struct, class, enum)
     */
    public struct TypeMeta {
        
        let name: String
        let superType: String
        
        /**
         Collect meta data for a type
         - parameter name: the name of the type
         - parameter superType: what the type inherits from (if anything)
         */
        internal init(name: String, superType: String) {
            self.name = name
            self.superType = superType
        }
    }
    
    /**
     Contains meta data associated with a property
     */
    public struct PropertyMeta {
        
        let name: String
        let type: String

        /**
         Collect meta data for a property
         - parameter name: the name of the property
         - parameter type: the type of the property
         */
        internal init(name: String, type: String) {
            self.name = name
            self.type = type
        }
    }
    
    static let leftParen = "(" as UnicodeScalar
    static let rightParen = ")" as UnicodeScalar
    static let lessThan = "<" as UnicodeScalar
    static let greaterThan = ">" as UnicodeScalar
    static let comma = "," as UnicodeScalar
    static let colon = ":" as UnicodeScalar
    static let semicolon = ";" as UnicodeScalar
    static let dash = "-" as UnicodeScalar
    static let beginTag = "<" + "#"
    static let endTag = "#" + ">"
    static let whitespace = CharacterSet.whitespacesAndNewlines
    
    /**
     The lines of text available for parsing. This comes from the editor.
     */
    private var lines: [String]
    
    /**
     The current line being processed.
     */
    private var currentLine: Int
    
    /**
     The text that has been parsed and is available for parsing. It is an accumulation of lines.
     */
    private var text: String
    
    /**
     The `unicodeScalars` view from the `text` property
     */
    private var chars: String.UnicodeScalarView
    
    /**
     The next position to read from in the `chars` view
     */
    private var pos: String.UnicodeScalarView.Index
    
    /**
     The prefix to add to any block comment
     */
    private var indent: String
    
    /**
     The errors the parser can encounter.
     */
    private enum ParseError : Error {
        case Unexpected(UnicodeScalar)
        case EndOfData
        case Underflow
    }
    
    /// Meta info if a function was last commented
    private(set) var funcMeta: FuncMeta?
    
    /// Meta info if a type was last commented
    private(set) var typeMeta: TypeMeta?

    /// Meta info if a property was last commented
    private(set) var propertyMeta: PropertyMeta?

    /**
     Initialize new FuncParser instance.
     */
    public init(lines: [String], currentLine: Int, indent: String) {
        self.lines = lines
        self.currentLine = currentLine
        self.indent = indent

        text = lines[currentLine]
        chars = text.unicodeScalars
        pos = chars.startIndex

        clear()
    }

    /**
     Clear any meta data collected from previous parse.
     */
    private func clear() {
        funcMeta = nil
        typeMeta = nil
        propertyMeta = nil
    }

    /**
     Create a Range instance that marks a set of characters in the parsed text.

     - Note: removes whitespace characters from the front and back of the set.
     
     - parameter start: the index of the first character in the range
     - parameter end: the index of the character *after* the last character in the range
     - returns: new Range instance
     */
    private func makeRange(start: String.UnicodeScalarIndex, end: String.UnicodeScalarIndex) throws -> Range {
        let subView = chars[start..<end]
        guard let s = (subView.index { !Parser.whitespace.contains($0) }) else {
            throw ParseError.EndOfData
        }

        let e = subView.reversed().index { !Parser.whitespace.contains($0) }
        return Range(view: subView, start: s, end: e!.base)
    }
    
    /**
     Obtain the next character to be parsed.
     - returns: next character
     - throws: `ParseError.EndOfData` if no more characters available
     */
    private func nextChar() throws -> UnicodeScalar {
        if pos == chars.endIndex {
            if currentLine == lines.count - 1 { throw ParseError.EndOfData }
            currentLine += 1
            text.append(lines[currentLine])
            chars = text.unicodeScalars
        }
        
        let c = chars[pos]
        pos = chars.index(after: pos)
        return c
    }
    
    /**
     Reverse over the character set, making the last character returned from `nextChar()` available again. This may
     be called multiple times, but the current code only needs to undo the most recent one.
     - throws: `ParseError.Underflow` if attempting to backup before start of parse text.
     */
    private func backup() throws {
        guard pos > chars.startIndex else { throw ParseError.Underflow }
        pos = chars.index(before: pos)
    }
    
    /**
     Find the next character that is not found in `CharacterSet.whitespaces`
     - returns: next non-whitespace character
     - throws: `ParseError.EndOfData` if no more characters available
     */
    private func nextNonWhiteSpace() throws -> UnicodeScalar {
        while true {
            let c = try nextChar()
            if !Parser.whitespace.contains(c) {
                return c
            }
        }
    }
    
    private static let nextTokenTerminals = Set([leftParen, comma, rightParen, colon])

    /**
     Build a range of characters until a whitespace character is found or one of '(', ',', '), or ':' is found
     - returns: Range of characters for the token
     - throws: `ParseError.EndOfData` if no more characters available
     */
    private func nextToken() throws -> Range {
        var start = pos
        var end = start
        while true {
            let c = try nextChar()
            if Parser.whitespace.contains(c) {
                if chars.distance(from: start, to: pos) > 1 {
                    end = chars.index(before: pos)
                    break
                }
                else {
                    start = pos
                    continue
                }
            }
            
            if Parser.nextTokenTerminals.contains(c) {
                if chars.distance(from: start, to: pos) > 1 {
                    try backup()
                }
                end = pos
                break
            }
        }
        
        return try makeRange(start: start, end: end)
    }
    
    private static let fetchTypeTerminals = Set([comma, rightParen, colon, semicolon])

    /**
     Fetch a type specifier, either for a function parameter or for the function return type.
     - returns: Range of characters in the type
     - throws: `ParseError.EndOfData` if no more data
     */
    private func fetchType() throws -> Range {
        var depth = 0
        let start = pos
        var end = start
        var foundSomething = false
        
        // If we reach the end of data, we might be OK if we were looking for a return type.
        //
        do {
            while true {
                let c = try nextChar()
                if depth == 0 {
                    if Parser.whitespace.contains(c) {
                        if foundSomething {
                            end = chars.index(before: pos)
                            break
                        }
                        else {
                            continue
                        }
                    }
                    
                    if Parser.fetchTypeTerminals.contains(c) || (c == Parser.leftParen && foundSomething) {
                        try backup()
                        end = pos
                        break
                    }
                }
                
                foundSomething = true
                
                if c == Parser.leftParen || c == Parser.lessThan {
                    depth += 1
                }
                
                if c == Parser.rightParen || c == Parser.greaterThan {
                    depth -= 1
                }
            }
        } catch {
            if foundSomething == false {
                throw ParseError.EndOfData
            }
            else {
                end = chars.endIndex
            }
        }
        
        return try makeRange(start: start, end: end)
    }
    
    /**
     Fetch the description of a function argument and store in a new `ArgInfo` instance.
     - parameter label: potential argument label
     - returns: `ArgInfo` instance
     - throws: `ParseError`
     */
    private func fetchArg(label: Range) throws -> ArgInfo {
        
        // If next token is ':' then we only have a name, not a label + name
        //
        var name = try nextToken()
        if name.first == Parser.colon {
            name = label
        }
        else {
            
            // Must be a ':' here
            //
            let c = try nextToken()
            if c.first != Parser.colon {
                throw ParseError.Unexpected(chars[c.start])
            }
        }
        
        // Obtain the argument type specification.
        //
        var type = try fetchType()
        if type.description == "inout" {
            type = try fetchType()
        }
        
        return ArgInfo(label: label, name: name, type: type)
    }
    
    /**
     Fetch the arguments of the function. There can be none, one or many.
     - returns: array of `ArgInfo` instances
     - throws: `ParseError`
     */
    private func fetchArgs() throws -> [ArgInfo] {
        var args = [ArgInfo]()
        while true {
            let label = try nextToken()
            if label.first == Parser.rightParen {
                return args
            }
            else if label.first == Parser.comma {
                continue
            }
            
            args.append(try fetchArg(label: label))
        }
    }
    
    private struct ReturnType {
        let type: String
        let canThrow: Bool
        
        init(type: String, canThrow: Bool) {
            self.type = type
            self.canThrow = canThrow
        }
    }

    /**
     Fetch the function's return type. No error if there is not one.

     - returns: ReturnType instance containing the return type specification and a flag if function throws errors
     - throws: `ParserError`
     */
    private func fetchReturnType() throws -> ReturnType {

        // We are looking for "->". If not found, then no return type.
        //
        var c: Range?
        do {
            c = try nextToken()
        } catch {
            return ReturnType(type: "", canThrow: false)
        }

        var canThrow = false
        if c?.description == "throws" {
            canThrow = true
            do {
                c = try nextToken()
            } catch {
                return ReturnType(type: "", canThrow: true)
            }
        }
        
        var returnType = ""
        if c?.description == "->" {
            returnType = try fetchType().description
            if returnType == "()" || returnType == "nil" {
                returnType = ""
            }
        }
        
        return ReturnType(type: returnType, canThrow: canThrow)
    }
    
    /**
     Create and return a generic block comment.
     - returns: array containing the lines of the comment
     */
    private func genericDef() -> [String] {
        var comment = [String]()
        comment.append("\(indent)/** \n")
        comment.append("\(indent) \(Parser.beginTag)Description\(Parser.endTag)")
        comment.append("\(indent) */\n")
        return comment
    }
    
    private func containerDef() -> [String] {
        do {
            let name = try fetchType()
            var superType = Range()
            let c = try nextNonWhiteSpace()
            if c == Parser.colon {
                superType = try fetchType()
            }
            
            typeMeta = TypeMeta(name: name.description, superType: superType.description)

            return containerBlockComment(meta: typeMeta!)
        } catch {
            return []
        }
    }

    private func propertyDef() -> [String] {
        do {
            let name = try fetchType()
            var type = Range()
            let c = try nextNonWhiteSpace()
            if c == Parser.colon {
                type = try fetchType()
            }

            propertyMeta = PropertyMeta(name: name.description, type: type.description)
            
            return propertyBlockComment(meta: propertyMeta!)
        } catch {
            return []
        }
    }
    
    /**
     Generate a block comment for an `init` statement
     - parameter token: either "init" or "init?"
     - returns: block comment
     */
    private func initDef(token: Range) -> [String] {
        let name = token.description
        do {
            // Scan for '('
            //
            let c = try nextNonWhiteSpace()
            if c != Parser.leftParen {
                throw ParseError.Unexpected(c)
            }
            
            let args = try fetchArgs()
            let returnType = try fetchReturnType()

            funcMeta = FuncMeta(name: name, args: args, returnType: returnType.type, canThrow: returnType.canThrow)
            return funcBlockComment(meta: funcMeta!)
        } catch {
            return []
        }
    }
    
    /**
     Generate a block comment for a `func` statement
     - returns: block comment
     */
    private func funcDef() -> [String] {
        do {
            let name = try fetchType()
            return initDef(token: name)
        } catch {
            return []
        }
    }
    
    /**
     Generate a function block comment. Inserts lines to document each argument in the call, and the return type if 
     it has one.
     
     - parameter name: the function name
     - parameter args: the array of `ArgInfo` argument descriptors (may be empty)
     - parameter returnType: contains the return type spec and a boolean indicating if function can throw
     - returns: array of String elements that make up the block comment in separate lines
     */
    private func funcBlockComment(meta: FuncMeta) -> [String] {
        var blk = [
            "\(indent)/**\n",
            "\(indent) \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n"
        ]
        for arg in meta.args {
            blk.append("\(indent) - parameter \(arg.name): \(Parser.beginTag)\(arg.name) description\(Parser.endTag)\n")
        }
        if !meta.returnType.isEmpty {
            blk.append("\(indent) - returns: \(Parser.beginTag)\(meta.returnType)\(Parser.endTag)\n")
        }
        if meta.canThrow {
            blk.append("\(indent) - throws: \(Parser.beginTag)error\(Parser.endTag)\n")
        }
        blk.append("\(indent) */\n")

        return blk
    }

    private func containerBlockComment(meta: TypeMeta) -> [String] {
        var blk = [
            "\(indent)/**\n",
            "\(indent) \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n",
            "\(indent) */\n"
        ]

        if !meta.superType.isEmpty {
            blk.insert("\(indent) - SeeAlso: `\(meta.superType)`\n", at: 2)
        }
        
        return blk
    }

    
    private func propertyBlockComment(meta: PropertyMeta) -> [String] {
        return [
            "\(indent)/// \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n",
        ]
    }
    
    /**
     Set of terms that will be ignored while looking for a `func` or `init`.
     */
    private static let ignoredTerms = Set(["public", "(", "set", ")", "private", "internal", "fileinternal",
                                           "override", "convenience", "required", "final", "static"])

    /**
     Parse a string for a valid function definition
     - parameter line: the text to scan
     - returns: true if found and valid, false otherwise
     */
    func parse() -> [String] {
        
        clear()

        while true {
            do {
                let kind = try nextToken()
                if Parser.ignoredTerms.contains(kind.description) {
                    continue
                }
                
                switch kind.description {
                case "struct", "class", "enum": return containerDef()
                case "var", "let": return propertyDef()
                case "func": return funcDef()
                case "init", "init?": return initDef(token: kind)
                default: return genericDef()
                }
            }
            catch {
                break
            }
        }
        
        return genericDef()
    }
}

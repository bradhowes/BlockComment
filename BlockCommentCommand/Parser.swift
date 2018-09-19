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
     Holds function argument information.
     */
    internal struct ArgInfo {

        /**
         Label for the argument when the function is invoked (given by the caller)
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
        internal init(label: String, name: String, type: String) {
            self.label = label
            self.name = name
            self.type = type
        }
    }

    /**
     Container of properties that describe the type of values returned by a function.
     */
    internal struct ReturnType {
        let type: String?
        let canThrow: Bool

        var hasReturn: Bool { return type != nil }
        var isNil: Bool { return type == "()" || type == "nil" || type == "Void" || type == "" }

        init(type: String?, canThrow: Bool) {
            self.type = type
            self.canThrow = canThrow
        }
    }

    /**
     Contains meta data associated wjith a func/init call.
     */
    internal struct FuncMeta {
        let name: String
        let args: [ArgInfo]
        let returnType: ReturnType

        /**
         Collect meta data for a func/init.

         - parameter name: the name of the func/init
         - parameter args: the argument specifications for the func/init
         - parameter returnType: the return type (empty string if returns nil)
         - parameter canThrow: true if can throw an error
         */
        internal init(name: String, args: [ArgInfo], returnType: ReturnType) {
            self.name = name
            self.args = args
            self.returnType = returnType
        }
    }

    /**
     Contains meta data associated with type (struct, class, enum)
     */
    internal struct TypeMeta {

        let name: String
        let superType: String?

        /**
         Collect meta data for a type
         - parameter name: the name of the type
         - parameter superType: what the type inherits from (if anything)
         */
        internal init(name: String, superType: String?) {
            self.name = name
            self.superType = superType
        }
    }

    /**
     Contains meta data associated with a property
     */
    internal struct PropertyMeta {
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

    internal static let atSign = "@" as Character
    internal static let poundSign = "#" as Character
    internal static let leftParen = "(" as Character
    internal static let rightParen = ")" as Character
    internal static let leftArray = "[" as Character
    internal static let rightArray = "]" as Character
    internal static let lessThan = "<" as Character
    internal static let greaterThan = ">" as Character
    internal static let leftBrace = "{" as Character
    internal static let rightBrace = "}" as Character
    internal static let comma = "," as Character
    internal static let colon = ":" as Character
    internal static let semicolon = ";" as Character
    internal static let dash = "-" as Character
    internal static let equals = "=" as Character
    internal static let beginTag = "<" + "#"
    internal static let endTag = "#" + ">"
    internal static let space = " " as Character
    internal static let questionMark = "?" as Character

    /**
     The lines of text available for parsing. This comes from the editor.
     */
    internal var lines: [String]

    /**
     The current line being processed.
     */
    internal var currentLine: Int

    /**
     The concatenation of lines so far
     */
    internal var text: String

    /**
     The next position to read from in the `chars` view
     */
    internal var pos: String.Index

    /**
     The prefix to add to any block comment
     */
    internal var indent: String

    /**
     The errors the parser can encounter.
     */
    internal enum ParseError : Error {
        case UnexpectedCharacter(Character)
        case UnexpectedToken(String)
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
    internal init(lines: [String], currentLine: Int, indent: String) {
        self.lines = lines
        self.currentLine = currentLine
        self.indent = indent

        text = lines[currentLine]
        pos = text.startIndex

        clear()
    }

    /**
     Clear any meta data collected from previous parse.
     */
    internal func clear() {
        funcMeta = nil
        typeMeta = nil
        propertyMeta = nil
    }

    /**
     Obtain the next character to be parsed.

     - returns: next character
     - throws: `ParseError.EndOfData` if no more characters available
     */
    internal func nextChar() throws -> Character {
        if pos != text.endIndex {
            let c = text[pos]
            pos = text.index(after: pos)
            return c
        }

        if currentLine == lines.count - 1 { throw ParseError.EndOfData }
        currentLine += 1
        let d = text.distance(from: text.startIndex, to: pos)
        text.append(lines[currentLine])
        pos = text.index(text.startIndex, offsetBy: d)
        return try nextChar()
    }

    /**
     Reverse over the character set, making the last character returned from `nextChar()` available again. This may
     be called multiple times, but the current code only needs to undo the most recent one.

     - throws: `ParseError.Underflow` if attempting to backup before start of parse text.
     */
    internal func backup() throws {
        guard pos > text.startIndex else { throw ParseError.Underflow }
        pos = text.index(before: pos)
    }

    /**
     Find the next character that is not found in `CharacterSet.whitespaces`.

     - returns: next non-whitespace character
     - throws: `ParseError.EndOfData` if no more characters available
     */
    internal func nextNonWhiteSpace() throws -> Character {
        while true {
            let c = try nextChar()
            if c > Parser.space {
                return c
            }
        }
    }

    /// Tokens that appear in pairs. We store both as the key and value so we can easily identify their sibling during parsing and popping of the
    /// token stack
    internal static let tokenPairs: [String:String] = {
        let s = [("(",")"), ("[","]"), ("{","}")]
        return Dictionary<String, String>(uniqueKeysWithValues: s + s.map { ($0.1, $0.0) })
    }()

    /// Tokens that can end another token
    internal static let nextTokenTerminals = Set((tokenPairs.keys + [",", ":"]).map { Character($0) }) // Set([leftParen, comma, rightParen, colon])

    /**
     Build a range of characters until a whitespace character is found or one of nextTokenTerminals is found.

     - returns: Range of characters for the token
     - throws: `ParseError.EndOfData` if no more characters available
     */
    internal func anyNextToken() throws -> String {
        var start = text.distance(from: text.startIndex, to: pos)
        var end = start
        while true {
            guard let c = try? nextChar() else {

               // Ran out of characters. Return only if we have something meaningful (non-whitespace)
                end = text.distance(from: text.startIndex, to: pos)
                if end != start {
                    return String(text[text.index(text.startIndex, offsetBy: start)..<text.index(text.startIndex, offsetBy: end)])
                }
                else {
                    throw ParseError.EndOfData
                }
            }

            if c <= Parser.space {
                let ts = text.distance(from: text.startIndex, to: pos)
                if ts - start > 1 {
                    end = text.distance(from: text.startIndex, to: text.index(before: pos))
                    break
                }
                start = ts
                continue
            }

            if Parser.nextTokenTerminals.contains(c) {
                var ts = text.distance(from: text.startIndex, to: pos)
                if ts - start > 1 {
                    try backup()
                    ts = text.distance(from: text.startIndex, to: pos)
                }
                end = ts
                break
            }

            // Assume it is a function return
            if c == Parser.greaterThan {
                end = text.distance(from: text.startIndex, to: pos)
                break
            }
        }

        return String(text[text.index(text.startIndex, offsetBy: start)..<text.index(text.startIndex, offsetBy: end)])
    }

    internal static let permsTerms = Set(["open", "public", "internal", "filepublic", "private"])
    internal static let ignoredTerms = Set([
        "class",
        "convenience",
        "final",
        "mutating",
        "optional",
        "override",
        "required",
        "static",
        ])

    /**
     Fetch the next token from the input.
     - returns: start and end of the token in the input
     - throws: UnexpectedToken, UnexpectedCharacter
     */
    internal func filteredNextToken() throws -> String {
        while true {
            let token = try anyNextToken()
            if token.first == "{" || token.first == "}" {
                try backup()
                throw Parser.ParseError.EndOfData
            }

            if token.first == Parser.atSign || Parser.ignoredTerms.contains(where: { (s) -> Bool in s == token }) {
                continue
            }

            if Parser.permsTerms.contains(where: { (s) -> Bool in s == token }) {
                let c = try nextChar()
                if c != Parser.leftParen {
                    try backup()
                    continue
                }
                else {
                    let kind = try anyNextToken()

                    // Skip something like public(set) -- I think
                    //
                    if kind != "set" {
                        throw Parser.ParseError.UnexpectedToken(String(kind))
                    }
                    let c = try nextChar()
                    if c != Parser.rightParen {
                        throw Parser.ParseError.UnexpectedCharacter(c)
                    }
                    continue
                }
            }

            if !Parser.ignoredTerms.contains(where: { (s) -> Bool in s == token}) {
                return token
            }
        }
    }

    /// Characters that act as terminals when scanning for a Swift type.
    internal static let fetchTypeTerminals = Set([leftBrace, comma, rightParen, colon, semicolon, rightArray, equals])

    /**
     Fetch a  type specifier, either for a function parameter or for the function return type.
     NOTE: this whole bit is hacked and should be reworked. See fetchType2 which needs some more
     work but is a bit cleaner. That said, current tests pass with this but not with the other.

     - returns: Range of characters in the type
     - throws: `ParseError.EndOfData` if no more data
     */
    internal func fetchType() throws -> String {
        _ = try nextNonWhiteSpace()
        try backup()

        var depth = 0
        let start = pos
        var end = start
        var foundSomething = false

        do {
            while true {
                let c = try nextChar()
                if depth == 0 {
                    
                    // Trailing '?' indicates an optional and is part of the type.
                    if c == Parser.questionMark {
                        end = pos
                        break
                    }

                    // A space is a terminator but only if there was something worthwhile before it
                    else if c <= Parser.space {
                        if foundSomething {
                            try backup()
                            end = pos
                            break
                        }
                        else {
                            continue
                        }
                    }

                    // Otherwise, stop on some known characters. The clause on the right takes care of a function name.
                    else if Parser.fetchTypeTerminals.contains(c) || (c == Parser.leftParen && foundSomething) {
                        try backup()
                        end = pos
                        break
                    }
                }

                // Handle nesting of various character pairs -- note that we just record a depth, but we do not check that
                // they are closed in the right order, much less that they make sense syntactically. While we are inside
                // of a span between open/close pairs, we just consume all of the the characters; there is no real
                // parsing being done.
                if c == Parser.leftParen || c == Parser.lessThan || c == Parser.leftArray {
                    depth += 1
                }
                else if c == Parser.rightParen || c == Parser.greaterThan || c == Parser.rightArray {
                    depth -= 1
                    end = pos;

                    if c == Parser.rightParen {
                        
                        // We are returning a tuple. We need to see if this is a closure.
                        //
                        let maybe = try fetchReturnType()
                        if maybe.hasReturn {
                            end = pos
                        }
                    }
                }

                foundSomething = true
            }
        } catch {
            if !foundSomething {
                throw ParseError.EndOfData
            }
            else {
                end = text.endIndex
            }
        }

        // Obtain a String of characdters that appear to be a type. Since we don't do any tokenizng of elements inside of "()" and "<>" pairs,
        // we sort of punt and just normalize on one space between items that are already separated by whitespace.
        let source = String(text[start..<end])
        let regex = try NSRegularExpression(pattern: "\\s+", options: NSRegularExpression.Options.caseInsensitive)
        return regex.stringByReplacingMatches(in: source, options: [], range: NSMakeRange(0, source.count), withTemplate: " ").trimmingCharacters(in: CharacterSet.whitespaces)
    }

    internal func fetchType2() throws -> String {
        var tokens: [String] = []
        var pairs: [String] = []
        while true {
            let token = try anyNextToken()
            tokens.append(token)

            if let closing = Parser.tokenPairs[token] {
                pairs.append(closing)
            }
            else if token == pairs.last {
                _ = pairs.popLast()
                if token == ")" {
                    let returnType = try fetchReturnType()
                    if returnType.hasReturn {
                        tokens.append("->")
                        tokens.append(returnType.type ?? "()")
                    }
                }
                if pairs.isEmpty {
                    break
                }
            }
            else if pairs.isEmpty {
                break
            }
        }

        return tokens.joined(separator: " ")
    }

    /**
     Fetch the description of a function argument and store in a new `ArgInfo` instance. Note that
     the presence of a default value is not done here but in the fetchArgs() definition.

     - parameter label: potential argument label
     - returns: `ArgInfo` instance
     - throws: `ParseError`
     */
    internal func fetchArg(label: String) throws -> ArgInfo {

        // If next token is ':' then we only have a name, not a label + name
        //
        var name = try filteredNextToken()
        if name.first == Parser.colon {
            name = label
        }
        else {

            // Must be a ':' here
            //
            let c = try filteredNextToken()
            if c.first != Parser.colon {
                throw ParseError.UnexpectedCharacter(text[c.startIndex])
            }
        }

        // Obtain the argument type specification.
        //
        var type = try fetchType()
        while type[type.startIndex] == Parser.atSign || type == "inout" {
            type = try fetchType()
        }

        return ArgInfo(label: label, name: name, type: type)
    }

    /**
     Fetch the arguments of the function. There can be none, one or many. Note that it will consume the
     closing ')' of the argument list.

     - returns: array of `ArgInfo` instances
     - throws: `ParseError`
     */
    internal func fetchArgs() throws -> [ArgInfo] {
        var args = [ArgInfo]()
        while true {
            let label = try filteredNextToken()
            if label.first == Parser.rightParen {
                return args
            }
            else if label.first == Parser.comma {
                continue
            }
            else if label.first == Parser.equals {

                // We have a default value for the argument. We ignore it for now.
                //
                _ = try filteredNextToken()

                // See if the next token indicates an object constructor
                //
                let c = try filteredNextToken()
                if c.first == Parser.leftParen {

                    // If the first token is a '(', treat as a tuple and recurse.
                    //
                    _ = try fetchArgs()
                }
                else {
                    try backup()
                }
                continue

            }
            
            args.append(try fetchArg(label: label))
        }
    }

    /**
     Fetch the function's return type. No error if there is not one.

     - returns: ReturnType instance containing the return type specification and a flag if function throws errors
     - throws: `ParserError`
     */
    internal func fetchReturnType() throws -> ReturnType {

        // We are looking for "->". If not found, then no return type.
        //
        var c: String?
        do {
            c = try filteredNextToken()
        } catch {
            return ReturnType(type: nil, canThrow: false)
        }

        var canThrow = false
        if c == "throws" {
            canThrow = true
            do {
                c = try filteredNextToken()
            } catch {
                return ReturnType(type: nil, canThrow: true)
            }
        }

        var returnType: String? = nil
        if c == "->" {
            returnType = try fetchType()
        }
        else {
            try backup()
        }

        return ReturnType(type: returnType, canThrow: canThrow)
    }

    /**
     Create and return a generic block comment.

     - returns: array containing the lines of the comment
     */
    internal func genericDef() -> [String] {
        var comment = [String]()
        comment.append("\(indent)/** \n")
        comment.append("\(indent) \(Parser.beginTag)Description\(Parser.endTag)")
        comment.append("\(indent) */\n")
        return comment
    }

    /**
     Create a block comment for a container (struct, class, extension)

     - returns: String array containing the comment block
     */
    internal func containerDef() -> [String] {
        do {
            let name = try fetchType()
            let c = try nextNonWhiteSpace()

            let superType: String? = {
                if c == Parser.colon {
                    return try? fetchType()
                }
                return nil
            }()

            typeMeta = TypeMeta(name: String(name), superType: superType)

            return containerComment(meta: typeMeta!)
        } catch {
            return []
        }
    }

    /**
     Create a one-line comment for a property.

     - returns: Array of one String
     */
    internal func propertyDef() -> [String] {
        do {
            let name = try fetchType()
            var type: String?
            let c = try nextNonWhiteSpace()
            if c == Parser.colon {
                type = try fetchType()
            }

            propertyMeta = PropertyMeta(name: String(name), type: String(type ?? ""))

            return propertyComment(meta: propertyMeta!)
        } catch {
            return []
        }
    }

    /**
     Generate a block comment for an `init` statement.

     - parameter token: either "init" or "init?"
     - returns: block comment
     */
    internal func initDef(token: String) -> [String] {
        let name = token
        do {
            // Scan for '('
            //
            let c = try nextNonWhiteSpace()
            if c != Parser.leftParen {
                throw ParseError.UnexpectedCharacter(c)
            }

            let args = try fetchArgs()
            let returnType = try fetchReturnType()

            funcMeta = FuncMeta(name: String(name), args: args, returnType: returnType)
            return funcComment(meta: funcMeta!)
        } catch {
            return []
        }
    }

    /**
     Generate a block comment for a `func` statement
     - returns: block comment
     */
    internal func funcDef() -> [String] {
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
    internal func funcComment(meta: FuncMeta) -> [String] {
        var blk = [
            "\(indent)/**\n",
            "\(indent) \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n",
        ]

        if !meta.args.isEmpty || !meta.returnType.isNil || meta.returnType.canThrow || (meta.returnType.hasReturn && !meta.returnType.isNil) {
            blk.append("\(indent)\n")
        }

        for arg in meta.args {
            blk.append("\(indent) - parameter \(arg.name): \(Parser.beginTag)\(arg.name) description\(Parser.endTag)\n")
        }

        if meta.returnType.hasReturn && !meta.returnType.isNil {
            blk.append("\(indent) - returns: \(Parser.beginTag)\(meta.returnType.type ?? "")\(Parser.endTag)\n")
        }

        if meta.returnType.canThrow {
            blk.append("\(indent) - throws: \(Parser.beginTag)error\(Parser.endTag)\n")
        }

        blk.append("\(indent) */\n")

        return blk
    }

    internal func containerComment(meta: TypeMeta) -> [String] {
        var blk = [
            "\(indent)/**\n",
            "\(indent) \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n",
            "\(indent) */\n"
        ]

        if let superType = meta.superType {
            if !superType.isEmpty {
                blk.insert("\(indent) - SeeAlso: `\(superType)`\n", at: 2)
            }
        }

        return blk
    }

    internal func propertyComment(meta: PropertyMeta) -> [String] {
        return [
            "\(indent)/// \(Parser.beginTag)Description for \(meta.name)\(Parser.endTag)\n",
        ]
    }

    public func markComment() -> [String] {
        let description: String = {
            do {
                let kind = try filteredNextToken()
                switch kind {
                case "struct", "class", "enum", "extension":
                    // TODO: improve on this?
                    let name = try fetchType()
                    return "\(name)"
                default:
                    break
                }
            } catch {

            }

            return "Description"
        }()

        return [
            "\(indent)// MARK: - \(Parser.beginTag)\(description)\(Parser.endTag)\n",
        ]
    }

    /**
     Parse a string for a valid function definition.

     - parameter line: the text to scan
     - returns: true if found and valid, false otherwise
     */
    public func makeBlockComment() -> [String] {

        clear()

        while true {
            do {
                let kind = try filteredNextToken()
                switch kind {
                case "struct", "class", "enum", "extension": return containerDef()
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

    public func makeMarkComment() -> [String] {
        clear()
        return markComment()
    }
}

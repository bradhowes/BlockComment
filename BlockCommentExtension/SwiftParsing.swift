// Copyright © 2019 Brad Howes. All rights reserved.

/**
 Scan for a sequence of characters that start/end with the given characters. Properly handles nesting, so we don't have
 to support recursive-descending in our parser -- we just ignore everything in-between the start/end as long as we have
 a balanced set of open and close characters.

 - parameter open:  the Character that opens the sequence
 - parameter close: the Character that closes the sequence
 - returns: new parser
 */
func balanced(_ open: Character, _ close: Character) -> Parser<String> {
    return Parser { it in
        let original = it
        it.skip { $0.isWhitespace }
        let start = it
        guard it.next() == open else {
            it = original
            return nil
        }

        var depth = 1
        var skipping = false
        while depth > 0 {
            guard let c = it.next() else { break }

            switch c {
            case "\\":
                skipping = true
                continue

            case close: if !skipping { depth -= 1 }
            case open: if !skipping { depth += 1 }

            default: break
            }
            skipping = false
        }

        if depth != 0 {
            it = original
            return nil
        }

        return start.span(to: it)
    }
}

/// Parser for tuples -- ignores content inside of the tuple
let tupleType = balanced("(", ")")

/// Parser for various identifiers such as property, struct, and enum names as well as argument labels.
let identifier = Parse.pat { $0.isLetter || $0.isNumber || $0 == "_" }

/// Parser for Swift atrributes that start with '@'. Support optional "(...)"
let attribute = zip(Parse.lit("@"), identifier, Parse.optional(tupleType))
    .map { $0.0 + $0.1 }

/// Parser for an optional sequence of one or more attributes, access level, etc.
let modifiers = Parse.any(Parse.first(
    attribute,
    Parse.lit("static"),
    Parse.lit("required"),
    Parse.lit("convenience"),
    Parse.lit("override"),
    Parse.lit("private(set)"),
    Parse.lit("private"),
    Parse.lit("fileprivate"),
    Parse.lit("internal"),
    Parse.lit("public"),
    Parse.lit("open")
), separatedBy: Parse.lit(" ", skipws: false))

/// Parser for an array type or default value -- ignores anything inside of the brackets
let arrayType = balanced("[", "]")

/// Parser of Swift types. Note that we do this dynamically so that we can have a valid `closure` definition which
/// depends on `tupleType`
let types = Parse.first { return [closure, arrayType, tupleType, identifier] }

/// Parser of return type specifications. The parsed value will be the type spec.
let returnType = zip(Parse.lit("->"), types).map { $0.1 }

/// Parser for a closure type definition. Parsed value will be concatenation of calling spec, "->", and return type.
let closure: Parser<String> = zip(tupleType, returnType).map { $0.0 + "->" + $0.1 }

/**
 Attributes associated with a Swift type.
 */
struct Type: Equatable {
    let spec: String
    let opt: Bool

    /// Parser for any type specification. Supports presence of optional "?".
    static let parser = zip(types, Parse.optional(Parse.lit("?", skipws: false)))
        .map { Type(spec: $0.0, opt: !$0.1.isEmpty) }
}

/// Parser for a closure default value
let closureValue = balanced("{", "}")

/// Parser for String default values -- ignores anything inside the quotes
let string = balanced("\"", "\"")

/// Parser for any default value setting
let value = Parse.first(
    string.map { _ in () },
    tupleType.map { _ in () },
    arrayType.map { _ in () },
    closureValue.map { _ in () },
    Parse.int.map { _ in () },
    Parse.double.map { _ in () },
    Parse.lit("true").map { _ in () },
    Parse.lit("false").map { _ in () }
)

/// Parser for a default value assignment set on a function argument
let defaultvalue = Parse.optional(zip(Parse.lit("="), value)).map { !$0.isEmpty }

/// Parser for optional attributes set on an argument
let argmods = Parse.any(Parse.first(Parse.lit("inout"), attribute), separatedBy: Parse.lit(" ", skipws: false))

/// Parser for an argument type which may have one or more modifiers before the type specification
let argtype = zip(argmods, Type.parser).map { $0.1 }

/**
 Attributes associated with a `func` argument
 */
struct Argument: Equatable {
    let name: String
    let type: Type
    let def: Bool

    /// Parser for a function argument specification. Successful parsing results in a 3-tuple with the argument's name,
    /// type spec, and a Bool indicating if there is a default value.
    static let parser = zip(
        Parse.first(zip(identifier, identifier).map { $0.0 != "_" ? $0.0 : $0.1 }, identifier),
        Parse.lit(":"),
        argtype,
        defaultvalue
    ).map { Argument(name: $0.0, type: $0.2, def: $0.3) }
}

/// Parser for a sequence of zero or more argument specifications separated by a ','
let arguments = Parse.any(Argument.parser, separatedBy: Parse.lit(","))

/// Parser for function names. Strips off any generic specification.
let functionName = Parse.pat { $0 != "(" } .map { (name: String) -> String in
    guard let pos = name.firstIndex(where: { $0.isWhitespace || $0 == "<" }) else { return name }
    return String(name[name.startIndex..<pos])
}

/**
 Protocol for parsers which can transform parsed info into a Swift comment. Implementations offer a computed property
 which is a list of String values that make up a Swift comment.
 */
protocol Commentable {
    var commentary: [String] {get}
}

extension Commentable {

    /**
     Utiltity method for Commentable parsers that creates magic tags in a comment that the user can access by repeated
     pressing of the TAB key.

     - parameter content: the text to appear in the tag
     - returns: the String to insert for the tag to appear
     */
    func makeTag(_ content: String) -> String { "<" + "#" + content + "#" + ">" }
}

/**
 Attributes associated with a parsed `func` specification.
 */
struct Function: Equatable, Commentable {
    let name: String
    let args: [Argument]
    let throwable: Bool
    let returns: String?

    /// Generate a block comment with information parsed from the function definition. The block starts with a
    /// description followed by one line for each function parameter. If the function returns, there is a line
    /// for describing what it returns. Finally, if the function can throw an exception, there is a line to
    /// describe what it will throw and why.
    var commentary: [String] {
        var lines = ["/**"]
        lines.append(" \(makeTag("Describe " + name))")
        if !args.isEmpty || returns != nil  || throwable {
            lines.append("")
            lines += args.map { " - parameter \($0.name): \(makeTag("Describe " + $0.name))" }
            if let r = returns { lines.append(" - returns \(makeTag(r))") }
            if throwable { lines.append(" - throws \(makeTag("Describe exceptions"))") }
        }
        lines.append(" */")
        return lines
    }

    /// Parser for matching function declarations. Transforms a match into a `Function` instance that describes the parsed
    /// function attributes.
    static let parser = zip(modifiers,
                            Parse.first(
                                zip(Parse.lit("func"), functionName).map { String($0.1) },
                                Parse.lit("subscript"),
                                Parse.lit("init?"),
                                Parse.lit("init")),
                            Parse.lit("("),
                            arguments,
                            Parse.lit(")"),
                            Parse.optional(Parse.lit("throws")),
                            Parse.optional(returnType))
        .map { Function(name: $0.1, args: $0.3, throwable: !$0.5.isEmpty,
                        returns: $0.6.filter { $0 != "()" && $0 != "Void" }.first ) }
}

/// Parser for a inheritance specification
let supertype = Parse.optional(zip(Parse.lit(":"), identifier))

/**
 Attributes for containers such as `class` and `enum`.
 */
struct Container: Equatable, Commentable {
    enum Kind {
        case `class`, `enum`, `struct`, `protocol`
    }

    let kind: Kind
    let name: String
    let inherits: String?

    var commentary: [String] {
        var lines = ["/**", " \(makeTag("Describe " + name))" ]
        if let parent = inherits {
            lines.append(" - SeeAlso: `\(parent)`")
        }
        lines.append(" */")
        return lines
    }

    /// Parser for `class`, `struct`, and `enum` specifications.
    static let parser = zip(modifiers,
                            Parse.first(
                                Parse.lit("class").map { _ in Container.Kind.class },
                                Parse.lit("struct").map { _ in Container.Kind.struct },
                                Parse.lit("enum").map { _ in Container.Kind.enum },
                                Parse.lit("protocol").map { _ in Container.Kind.protocol }),
                            identifier, supertype)
        .map { Container(kind: $0.1, name: $0.2, inherits: $0.3.first.map { $0.1 } ) }
}

/**
 Attributes for a member of a container such as a `let` or `var` member.
 */
struct Property: Equatable, Commentable {
    enum Kind { case `var`, `let`, `typealias`, `associatedtype` }
    let kind: Kind
    let name: String

    var commentary: [String] { return ["/// \(makeTag("Describe " + name))"] }

    /// Parser for properties
    static let parser = zip(modifiers,
                            Parse.first(
                                zip(Parse.optional(Parse.lit("lazy")), Parse.lit("var")).map { _ in Property.Kind.var },
                                Parse.lit("typealias").map { _ in Property.Kind.typealias },
                                Parse.lit("associatedtype").map { _ in Property.Kind.associatedtype },
                                Parse.lit("let").map { _ in Property.Kind.let }),
                            identifier).map { Property(kind: $0.1, name: $0.2) }
}

/// General parser which returns a collection of lines if there is a commentable item after the cursor. Note that the
/// last action always succeeds and returns a default comment.
let commentable = Parse.first(Function.parser.map { $0.commentary },
                              Container.parser.map { $0.commentary },
                              Property.parser.map { $0.commentary },
                              Parse.always("/// ").map { [$0] })

/**
 Parser the given Source and return an array of comment strings

 - parameter source: the Source to parse
 - returns: the comment found for the source
 */
public func parse(source: Source) -> [String] {
    return commentable.parse(source)?.map { source.indentation + $0 } ?? []
}

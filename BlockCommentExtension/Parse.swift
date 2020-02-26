// Copyright © 2019 Brad Howes. All rights reserved.
//
// This code uses ideas presented by POINT•FREE (https://www.pointfree.co) in their discussions on parsers. The
// videos are subscriber-based (and highly recommended), but the Swift playgrounds that were used and discussed
// can be found on Github at https://github.com/pointfreeco/episode-code-samples

/**
 Pseudo-namespace for general parsing utilities.
 */
public enum Parse {

    /**
     Utility to scan over text and capture the result.

     - parameter start: the iterator to use for characters
     - parameter skipws: if true, skip over whitespace before parsing
     - parameter iter: closure to execute to scan/parse the text
     - parameter check: closure to execute to determine if the parse was successful and to generate an `A` instance if so
     - returns: optional `A` instance
     */
    public static func capture<A>(_ start: inout Source.Iterator, skipws: Bool, iter: (inout Source.Iterator) -> Void,
                                  check: (String)-> A?) -> A? {
        if skipws { start.skip { $0.isWhitespace } }
        var it = start
        iter(&it)
        guard let value = check(start.span(to: it)) else { return nil }
        start = it
        print("captured: '\(value)' remaining: '\(it.remaining)")
        return value
    }

    /// Parser for decimal integer values
    public static let int = Parser<Int> { it in
        capture(&it, skipws: true, iter: { $0.skip { $0.isNumber } }, check: { Int($0) })
    }

    //assert(int.parse("  123") == 123)

    /// Parser for floating-point values
    public static let double = Parser<Double> { it in
        capture(&it, skipws: true, iter: { $0.skip { $0.isNumber || $0 == "." } }, check: { Double($0) })
    }

    //assert(double.parse(" 123.456  ") == 123.456)

    /// Parser for a single character -- the result is just the value of the next character from the iterator.
    public static let char = Parser<Character> { it in
        guard let c = it.next() else { return nil }
        return c
    }

    /**
     Obtain a parser for literal value

     - parameter p: the literal value to expect
     - parameter optiona: if true then succeed even if the literal does not exist
     - parameter skipws: if true (default) allow for whitespace characters before literal
     - returns: new parser that matches on the given literal
     */
    public static func lit(_ p: String, optional: Bool = false, skipws: Bool = true) -> Parser<String> {
        Parser { it in
            capture(&it, skipws: skipws, iter: { $0.skip(count: p.count) }, check: { $0 == p || optional ? p : nil })
        }
    }

    /**
     Obtain a parser that matches a class of characters.

     - parameter skipws: if true (default) skip whitespace characters before parsing
     - parameter p: the predicate function that indicates if a character belongs in the desired class
     - returns: new parser for matching character classes
     */
    public static func pat(skipws: Bool = true, while p: @escaping (Character) -> Bool) -> Parser<String> {
        Parser { it in
            capture(&it, skipws: skipws, iter: { $0.skip(p) }, check: { !$0.isEmpty ? $0 : nil })
        }
    }

    /**
     Obtain a parser that always matches without consuming any text.

     - parameter a: the value to return for the parser
     - returns: the new parser
     */
    public static func always<A>(_ a: A) -> Parser<A> { Parser<A> { _ in a } }

    //always(123).parse("testing")

    /**
     Obtain a parser that succeeds when the first parser in a collection of parsers succeeds (at most one).

     - parameter ps: the collection of parsers
     - returns: new parser
     */
    public static func first<A>(_ ps: [Parser<A>]) -> Parser<A> { first { ps } }

    /**
     Obtain a parser that succeeds when the first parser in a collection of parsers succeeds (at most one).

     - parameter ps: the collection of parsers
     - returns: new parser
     */
    public static func first<A>(_ ps: Parser<A>...) -> Parser<A> { first { ps } }

    /**
     Obtain a parser that succeeds when the first parser in a collection of parsers succeeds (at most one). This variant
     obtains the collection from the given closure, thus delaying evaluation of the collection until when it is actually
     needed.

     - parameter ps: closure to invoke to obtain the collection to iterate over
     - returns: new parser
     */
    public static func first<A>(_ ps: @escaping () -> [Parser<A>]) -> Parser<A> {
        Parser { it -> A? in
            for p in ps() {
                if let match = p.scanner(&it) {
                    print("first: match '\(match)' remaining: '\(it.remaining)'")
                    return match
                }
            }
            print("first: nil")
            return nil
        }
    }

    /**
     Obtain a parser that will match zero or more times with a given parser, with matches separated by a given separator.

     - parameter p: the parser to match with
     - parameter s: the separator to look for
     - returns: the new parser
     */
    public static func any<A>(_ p: Parser<A>, separatedBy s: Parser<String>) -> Parser<[A]> {
        Parser { it in
            var rest = it
            var matches: [A] = []
            while let match = p.scanner(&it) {
                print("any: match '\(match)' remaining: '\(it.remaining)'")
                rest = it
                matches.append(match)
                if s.scanner(&it) == nil {
                    print("any: no separator")
                    break
                }
            }
            it = rest

            print("any: \(matches)")
            return matches
        }
    }

    /**
     Parser for an optional item. Always results in an Array[A], but it will be empty if the parsing fails.

     - parameter p: the parser to run internally.
     - returns: new parser
     */
    public static func optional<A>(_ p: Parser<A>) -> Parser<[A]> {
        Parser { it in
            guard let match = p.scanner(&it) else { return [] }
            return [match]
        }
    }
}

/**
 Define zip operation on two Parser instances such that parsing is successful iff both parsers match on input in
 sequential order.

 - parameter a: first parser to execute
 - parameter b: second parser to execute
 - returns: new parser
 */
public func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
    Parser { it -> (A, B)? in
        let original = it
        guard let matchA = a.scanner(&it) else { return nil }
        guard let matchB = b.scanner(&it) else {
            it = original
            return nil
        }
        return (matchA, matchB)
    }
}

/**
 Define zip operation on three Parser instances such that parsing is successful iff all parsers match on input in
 sequential order.

 - parameter a: first parser to execute
 - parameter b: second parser to execute
 - parameter c: third parser to execute
 - returns: new parser
*/
public func zip<A, B, C>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>) -> Parser<(A, B, C)> {
    zip(a, zip(b, c)).map { a, rest in (a, rest.0, rest.1) }
}

/**
 Define zip operation on four Parser instances such that parsing is successful iff all parsers match on input in
 sequential order.

 - parameter a: first parser to execute
 - parameter b: second parser to execute
 - parameter c: third parser to execute
 - parameter d: fourth parser to execute
 - returns: new parser
*/
public func zip<A, B, C, D>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>) ->
    Parser<(A, B, C, D)> {
        zip(a, zip(b, c, d)).map { a, rest in (a, rest.0, rest.1, rest.2) }
}

public func zip<A, B, C, D, E>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>,
                               _ e: Parser<E>) -> Parser<(A, B, C, D, E)> {
    zip(a, zip(b, c, d, e)).map { a, rest in (a, rest.0, rest.1, rest.2, rest.3) }
}

public func zip<A, B, C, D, E, F>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>,
                                  _ e: Parser<E>, _ f: Parser<F>) -> Parser<(A, B, C, D, E, F)> {
    zip(a, zip(b, c, d, e, f)).map { a, rest in (a, rest.0, rest.1, rest.2, rest.3, rest.4) }
}

public func zip<A, B, C, D, E, F, G>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>,
                                     _ e: Parser<E>, _ f: Parser<F>, _ g: Parser<G>) ->
    Parser<(A, B, C, D, E, F, G)> {
        zip(a, zip(b, c, d, e, f, g)).map { a, rest in (a, rest.0, rest.1, rest.2, rest.3, rest.4, rest.5) }
}

public func zip<A, B, C, D, E, F, G, H>(_ a: Parser<A>, _ b: Parser<B>, _ c: Parser<C>, _ d: Parser<D>,
                                        _ e: Parser<E>, _ f: Parser<F>, _ g: Parser<G>, _ h: Parser<H>) ->
    Parser<(A, B, C, D, E, F, G, H)> {
        zip(a, zip(b, c, d, e, f, g, h)).map { a, rest in (a, rest.0, rest.1, rest.2, rest.3, rest.4, rest.5, rest.6) }
}

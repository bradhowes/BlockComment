// Copyright © 2016-2019 Brad Howes. All rights reserved.
//
// This code uses ideas presented by POINT•FREE (https://www.pointfree.co) in their discussions on parsers. The
// videos are subscriber-based (and highly recommended), but the Swift playgrounds that were used and discussed
// can be found on Github at https://github.com/pointfreeco/episode-code-samples

/**
 Definition of a text scanner/parser that converts input characters into an instance of A.
 */
public struct Parser<A> {

    /// Prototype of the function that transforms a span of text starting at a given iterator into an instance of A.
    /// The function takes in an iterator to the next character to process. The function will update the iterator as it
    /// advances, but it can also set the iterator to a new value if necessary to undo any advances.
    public typealias Scanner = (inout Source.Iterator) -> A?

    /// Common value that represents a unparsable entity
    public static var never: Parser { Parser { _ in nil } }

    /// Function that transforms given text into an instance of A or nil if the transformation cannot take place
    public let scanner: Scanner

    /**
     Attempt to parse a given string. Only used for testing.

     - parameter str: what to parse
     - returns: 2-tuple containing the optional A instance, and the remaining, unprocessed string.
     */
    public func parse(_ str: String) -> A? {
        parse(Source(lines: [str], firstLine: 0))
    }

    /**
     Attempt to parse a given text Source.

     - parameter source: the source of the text to parse
     - returns: optional `A` instance built from the parsings
     */
    public func parse(_ source: Source) -> A? {
        var it = source.makeIterator()
        it.skip { $0.isWhitespace }
        return self.scanner(&it)
    }

    /**
     Create parser that will attempt to parse text with the internal `scanner` and then apply a transform from `A`
     result to a `B` instance.

     - parameter f: transform function to apply
     - returns: new parser
     */
    public func map<B>(_ f: @escaping (A) -> B) -> Parser<B> { Parser<B> { it in self.scanner(&it).map(f) } }

    /**
     Convenience method that transforms all `A` instances into the given value.

     - parameter target: the value to transform into
     - returns: new parser
     */
    public func to<B>(_ target: B) -> Parser<B> { map { _ in target } }

    /**
     Create parser that will do the following:

     - attempt to parse the text with internal `scanner`
     - if successful, transform the output `A` instance into a new parser
     - attempt to parse using new parser

     If either parse fails, restores the iterator to its initial state.

     - parameter f: transform function to use to generate a new parser from an `A` instance
     - returns: new Parser
     */
    public func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        Parser<B> { it in
            let original = it
            guard let matchB = self.scanner(&it).map(f)?.scanner(&it) else {
                it = original
                return nil
            }
            return matchB
        }
    }

    /// Obtain a parser that results in a Void type, thus forgetting the type `A`.
    public var forget: Parser<Void> { map { _ in () } }
}

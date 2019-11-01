// Source.swift
// Copyright © 2019 Brad Howes. All rights reserved.

/**
 Provider of Character values to be parsed.
 */
public struct Source {

    /**
     Custom iterator over Character values from a Source.
     */
    public struct Iterator {
        private let source: Source
        private var currentLine: Int
        private var currentPos: String.Index

        /**
         Obtain new iterator for a Source. Starts at the first line of the source

         - parameter source: the source of String values
         - parameter currentLine: the line to start at
         */
        public init(source: Source, currentLine: Int) {
            self.init(source: source, currentLine: currentLine, currentPos: source.lines[currentLine].startIndex)
        }

        internal init(source: Source, currentLine: Int, currentPos: String.Index) {
            self.source = source
            self.currentLine = currentLine
            self.currentPos = currentPos
        }

        /// Obtain the current character
        private var value: Character? {
            let line = source.lines[currentLine]
            if currentPos == line.endIndex {
                if currentLine == source.lines.count - 1 {
                    return nil
                }
                return " "
            }
            return line[currentPos]
        }
    }

    private let lines: [String]
    private let firstLine: Int

    /**
     Construct new source which will begin parsing at a specific line

     - parameter lines: the lines to parse
     - parameter firstLine: the first line to parse
     */
    public init(lines: [String], firstLine: Int) {
        self.lines = lines
        self.firstLine = firstLine
    }
}

extension Source: Sequence {

    /**
     Create a new iterator starting at the current line of the source.

     - returns: new iterator
     */
    public func makeIterator() -> Source.Iterator { Iterator(source: self, currentLine: firstLine) }
}

extension Source {

    /// Iterator to the end of all of the lines. Only used for debugging purposes.
    public var end: Iterator {
        Iterator(source: self, currentLine: lines.count - 1, currentPos: lines[lines.count - 1].endIndex)
    }

    /// Obtain the indentation of the first line.
    public var indentation: String { String(lines[firstLine].prefix { $0.isWhitespace }) }
}

extension Source.Iterator: IteratorProtocol {

    /**
     Advance the iterator and return the character there.

     - returns: next Character or nil if no more
     */
    @discardableResult
    public mutating func next() -> Character? {
        let line = source.lines[currentLine]
        if currentPos == line.endIndex {
            if currentLine == source.lines.count - 1 {
                return nil
            }
            currentLine += 1
            currentPos = source.lines[currentLine].startIndex
            return " "
        }
        defer { currentPos = line.index(after: currentPos) }
        return line[currentPos]
    }
}

extension Source.Iterator {

    /// Obtain the text that has yet to be visited by the iterator. NOTE: this is only used for debugging.
    public var remaining: String { span(to: source.end) }

    /**
     Advance the iterator as long as the *current* character it points to fulfills the given condition.

     - parameter cond: condition to check
     */
    public mutating func skip(_ cond: (Character) -> Bool) {
        while let c = value, cond(c) {
            next()
        }
    }

    /**
     Advance the iterator a given number of times.

     - parameter count: number of times to advance
     */
    public mutating func skip(count: Int) {
        for _ in (0..<count) { next() }
    }

    /**
     Obtain the characters between two iterators.

     - parameter to: the ending iterator
     - returns: String containing characters in the iterator range
     */
    public func span(to: Self) -> String {
        let line = source.lines[currentLine]
        return currentLine == to.currentLine ? String(line[(currentPos)..<(to.currentPos)]) :
            String(line.dropFirst(line.distance(from: line.startIndex, to: currentPos))) + " " +
            Self(source: self.source, currentLine: currentLine + 1).span(to: to)
    }
}


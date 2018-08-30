//
//  ParserTests.swift
//  BlockCommentTests
//
//  Created by Brad Howes on 8/26/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import XCTest

@testable import BlockComment

class ParserTests: XCTestCase {
    func testNextCharacterThrowsIfNothingLeft() {
        let lines = [""]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        XCTAssertThrowsError(try p.nextChar())
    }

    func testNextCharacterThrowsIfNothingLeftInMultipleLines() {
        let lines = ["", ""]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        XCTAssertThrowsError(try p.nextChar())
    }

    func testNextCharacterReturnsNextCharacter() {
        let lines = ["a", "bc", "d", ""]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        var c = try! p.nextChar()
        XCTAssertEqual(c, "a" as Character)
        c = try! p.nextChar()
        XCTAssertEqual(c, "b" as Character)
        c = try! p.nextChar()
        XCTAssertEqual(c, "c" as Character)
        c = try! p.nextChar()
        XCTAssertEqual(c, "d" as Character)
        XCTAssertThrowsError(try p.nextChar())
    }
    
    func testBackupThrowsIfFirstPosition() {
        let lines = [""]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        XCTAssertThrowsError(try p.backup())
    }

    func testBackupThrowsMovesToPreviousPosition() {
        let lines = ["ab"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        var c = try! p.nextChar()
        XCTAssertEqual(c, "a" as Character)
        XCTAssertNoThrow(try p.backup())
        c = try! p.nextChar()
        XCTAssertEqual(c, "a" as Character)
        c = try! p.nextChar()
        XCTAssertEqual(c, "b" as Character)
        XCTAssertNoThrow(try p.backup())
        c = try! p.nextChar()
        XCTAssertEqual(c, "b" as Character)
    }
    
    func testNextNonWhitespace() {
        let lines = ["  ", " a b ", "  "]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        var c = try! p.nextNonWhiteSpace()
        XCTAssertEqual(c, "a" as Character)
        c = try! p.nextNonWhiteSpace()
        XCTAssertEqual(c, "b" as Character)
        XCTAssertThrowsError(try p.nextNonWhiteSpace())
    }
    
    func testAnyNextToken() {
        let lines = ["one two(three, four)   five   :  six     "]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        var t = try! p.anyNextToken()
        XCTAssertEqual(t, "one")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "two")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "(")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "three")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, ",")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "four")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, ")")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "five")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, ":")
        t = try! p.anyNextToken()
        XCTAssertEqual(t, "six")
    }

    func testfilteredNextTokenSkipsIgnoredTerms() {
        let lines = ["@blah final mutating public private(set) static mutating let var = @bfoobar 1"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        var t = try! p.filteredNextToken()
        XCTAssertEqual(t, "let")
        t = try! p.filteredNextToken()
        XCTAssertEqual(t, "var")
        t = try! p.filteredNextToken()
        XCTAssertEqual(t, "=")
        t = try! p.filteredNextToken()
        XCTAssertEqual(t, "1")
    }

    func testFetchTypeAtEndOfData() {
        let lines = ["  Int"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchType()
        XCTAssertEqual("Int", a)
    }
    
    func testFetchTypeBeforeSpace() {
        let lines = ["  Int  "]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchType()
        XCTAssertEqual("Int", a)
    }
    
    func testFetchTypeOptional() {
        let lines = ["  Int?  "]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchType()
        XCTAssertEqual("Int?", a)
    }
    
    func testFetchTypeBeforeTeriminal() {
        for terminal in Parser.fetchTypeTerminals {
            let lines = ["  Int\(terminal)z "]
            let p = Parser(lines: lines, currentLine: 0, indent: "  ")
            let a = try! p.fetchType()
            XCTAssertEqual("Int", a)
        }
    }

    func testFetchFunctionType() {
        let lines = ["  ((Int?, Float)) -> ())"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchType()
        XCTAssertEqual("((Int?, Float)) -> ()", a)
    }

    func testFetchArgsNone() {
        let lines = ["   )"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchArgs()
        XCTAssertEqual(0, a.count)
    }

    func testFetchFuncArg() {
        let lines = ["z: (Int) -> ())"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchArgs()
        XCTAssertEqual(1, a.count)
        XCTAssertEqual("z", a[0].label)
        XCTAssertEqual("z", a[0].name)
        XCTAssertEqual("(Int) -> ()", a[0].type)
    }
    
    func testFetchArgs() {
        let lines = ["foo bar: Int, blah: Int?, baz: (Int, Int)?, z: (Int) -> ())"]
        let p = Parser(lines: lines, currentLine: 0, indent: "  ")
        let a = try! p.fetchArgs()
        XCTAssertEqual(4, a.count)
        XCTAssertEqual("foo", a[0].label)
        XCTAssertEqual("bar", a[0].name)
        XCTAssertEqual("Int", a[0].type)

        XCTAssertEqual("blah", a[1].label)
        XCTAssertEqual("blah", a[1].name)
        XCTAssertEqual("Int?", a[1].type)

        XCTAssertEqual("baz", a[2].label)
        XCTAssertEqual("baz", a[2].name)
        XCTAssertEqual("(Int, Int)?", a[2].type)

        XCTAssertEqual("z", a[3].label)
        XCTAssertEqual("z", a[3].name)
        XCTAssertEqual("(Int) -> ()", a[3].type)
    }
}

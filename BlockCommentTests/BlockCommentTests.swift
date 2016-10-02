//  BlockCommentTests.swift
//  BlockCommentTests
//
//  Created by Brad Howes on 9/30/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest


class BlockCommentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testComplex() {
        let lines = ["  override internal \t\tfunc \tcomp김lex   (_ a김: inout Int, o23김 b: (one: Int, two: Int, three: Int), cc김 c김: inout Double) throws -> (four: Int, five: \t\t(six: Int, seven: Int))      \n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.parse()
        let x = z.funcMeta!
        
        XCTAssertEqual(x.name, "comp김lex")
        XCTAssertFalse(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 3)
        XCTAssertEqual(x.args[0].name, "a김")
        XCTAssertEqual(x.args[0].type, "Int")
        XCTAssertEqual(x.args[1].name, "b")
        XCTAssertEqual(x.args[1].type, "(one: Int, two: Int, three: Int)")
        XCTAssertEqual(x.args[2].name, "c김")
        XCTAssertEqual(x.args[2].type, "Double")
        
        XCTAssertEqual(y.count, 8)
        XCTAssertEqual(y[0], "  /**\n")
        XCTAssertEqual(y[7], "   */\n")
    }
    
    func testMinimal() {
        let lines = ["func a()\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.parse()
        let x = z.funcMeta!
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(x.name, "a")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 0)
    }
    
    func testThrows() {
        let lines = ["func a()throws\n", "func a() throws\n", "func a() throws -> Double\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        
        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertFalse(z.funcMeta!.returnType.isEmpty)
    }
    
    func testGeneric() {
        let lines = ["func a<T: Blah where T.Element = Foo>   (          )     \n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.name, "a<T: Blah where T.Element = Foo>")
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
    }
    
    func testStruct() {
        let lines = ["struct FooBar: Blah {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.parse()
        XCTAssertEqual(y.count, 4)
        XCTAssertEqual(z.typeMeta!.name, "FooBar")
        XCTAssertEqual(z.typeMeta!.superType, "Blah")
    }
    
    func testInit() {
        let lines = ["init()\n", "init? ()\n", "convenience init?()\n",
                     "    init(view: String.UnicodeScalarView, start: String.UnicodeScalarIndex, end: String.UnicodeScalarIndex) {\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init")
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init?")
        
        y = Parser(lines: lines, currentLine: 2, indent: " ").parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init?")
        
        z = Parser(lines: lines, currentLine: 3, indent: " ")
        y = z.parse()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 3)
        XCTAssertEqual(z.funcMeta!.name, "init")
    }
    
    func testProperty() {
        let lines = ["public private(set) var blah:Int\n",
                     "private static var blah : Int\n",
                     "let blah :Int\n",
                     "let blah : (_ x: Int, _ y: Int) -> Int\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.parse()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.parse()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")

        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.parse()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")
    }
    
    func NOT_testProperty() {
        let _ : (_ x: Int, _ y: Int) -> Int
        let lines = ["let blah : (_ x: Int, _ y: Int) -> Int\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        _ = z.parse()

        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")
    }

}

//  BlockCommentTests.swift
//  BlockCommentTests
//
//  Created by Brad Howes on 9/30/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import XCTest

protocol Foo {
    static func save(to url: URL, blah: @escaping (Int64) -> ()) -> ()
}

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
        let y = z.makeBlockComment()
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
        
        XCTAssertEqual(y.count, 9)
        XCTAssertEqual(y[0], "  /**\n")
        XCTAssertEqual(y[8], "   */\n")
    }
    
    func test2() {
        let lines = ["static func save(to url: URL, done: @escaping (Int64)   ->    ()) {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "done")
        XCTAssertEqual(y.count, 6)
    }

    func testReturnsDouble() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> Double {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isEmpty)
        XCTAssertEqual(x.returnType, "Double")
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 7)
    }
    
    func testReturnsArray() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> [Int] {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isEmpty)
        XCTAssertEqual(x.returnType, "[Int]")
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 7)
    }
    
    func testReturnsMap() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> [Int:Int] {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 7)
    }
    
    func testReturnsVoid() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> Void {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 6)
    }
    
    func testReturnsNil() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> nil {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 6)
    }
    
    func testReturnsEmptyTuple() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> () {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 6)
    }
    
    func testPrototype() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> ()"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        print(y)
        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(y.count, 6)
    }
    
    func testDefaultArgument() {
        let lines = ["private init(timestampGenerator: TimestampGeneratorInterface = TimestampGenerator()) {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "init")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 1)
        XCTAssertEqual(x.args[0].name, "timestampGenerator")
        XCTAssertEqual(x.args[0].type, "TimestampGeneratorInterface")
        XCTAssertEqual(y.count, 5)
    }
    
    func testMinimal() {
        let lines = ["func a()\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(x.name, "a")
        XCTAssertTrue(x.returnType.isEmpty)
        XCTAssertEqual(x.args.count, 0)
    }
    
    func testThrows() {
        let lines = ["func a()throws\n", "func a() throws\n", "func a() throws -> Double\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        
        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertFalse(z.funcMeta!.returnType.isEmpty)
    }

    func testGeneric() {
        let lines = ["func a<T: Blah where T.Element = Foo>   (          )     \n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.name, "a<T: Blah where T.Element = Foo>")
        XCTAssertTrue(z.funcMeta!.returnType.isEmpty)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
    }
    
    func testStruct() {
        let lines = ["struct FooBar: Blah {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        XCTAssertEqual(y.count, 4)
        XCTAssertEqual(z.typeMeta!.name, "FooBar")
        XCTAssertEqual(z.typeMeta!.superType, "Blah")
    }
//
    func testInit() {
        let lines = ["init()\n", "init? ()\n", "convenience init?()\n",
                     "    init(view: String.UnicodeScalarView, start: String.UnicodeScalarIndex, end: String.UnicodeScalarIndex) {\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init")
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init?")
        
        y = Parser(lines: lines, currentLine: 2, indent: " ").makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init?")
        
        z = Parser(lines: lines, currentLine: 3, indent: " ")
        y = z.makeBlockComment()
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
        var y = z.makeBlockComment()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")
        
        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.makeBlockComment()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")

        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.makeBlockComment()
        XCTAssertEqual(y.count, 1)
        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "Int")
    }

    func testProperty2() {
        let _ : (_ x: Int, _ y: Int) -> Int
        let lines = ["let blah : (_ x: Int, _ y: Int) -> Int\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        _ = z.makeBlockComment()

        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "(_ x: Int, _ y: Int) -> Int")
    }

}

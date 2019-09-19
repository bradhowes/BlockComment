// Copyright © 2019 Brad Howes. All rights reserved.
//

import XCTest

class BlockCommentAppTests: XCTestCase {

    func testComplex() {
        let lines = ["  override internal \t\tfunc \tcomp김lex   (_ a김: inout\n",
                     "Int, o23김 b: (one: Int, two:\n",
                     "Int, three: Int), cc김 c김: inout Double) throws \n",
                     "-> (four: Int, five: \t\t(six: Int, seven: Int))      \n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "comp김lex")
        XCTAssertTrue(x.returnType.hasReturn)
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "(four: Int, five: (six: Int, seven: Int))")
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

    func testComplex2() {
        let lines = ["func record(clock: MusicTimeStamp, recorder: ((MusicTimeStamp, Note)->Void)? = nil) -> MusicTimeStamp {"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta
        XCTAssertEqual(y.count, 7)
        XCTAssert(x != nil)
        XCTAssertEqual(x?.name, "record")
    }
    func testNoIndentation() {
        let lines = ["static func save(to url: URL, done: @escaping (Int64)   ->    ())"]
        let z = Parser(lines: lines, currentLine: 0, indent: "")
        let y = z.makeBlockComment()

        XCTAssertEqual(y.count, 6)
        XCTAssertEqual(y.first, "/**\n")
        XCTAssertEqual(y.last, " */\n")
    }

    func testLargeIndentation() {
        let lines = ["static func save(to url: URL, done: @escaping (Int64)   ->    ())"]
        let z = Parser(lines: lines, currentLine: 0, indent: String(repeating: " ", count: 20))
        let y = z.makeBlockComment()

        XCTAssertEqual(y.count, 6)
        XCTAssertEqual(y.first, String(repeating: " ", count: 20) + "/**\n")
        XCTAssertEqual(y.last,  String(repeating: " ", count: 20) + " */\n")
        for each in y {
            XCTAssertEqual(String(each.prefix(20)), String(repeating: " ", count: 20))
        }
    }

    func testCurrentLine() {
        let lines = ["static\n",
                     "func first(a: Int) -> Double {\n",
                     "\n",
                     "func second(b: Int, c: Double) -> String {\n",
                     "\n"]
        for currentLine in 0..<2 {
            let z = Parser(lines: lines, currentLine: currentLine, indent: "  ")
            let y = z.makeBlockComment()
            let x = z.funcMeta!

            XCTAssertEqual(x.name, "first")
            XCTAssertTrue(x.returnType.hasReturn)
            XCTAssertEqual(x.returnType.type, "Double")
            XCTAssertEqual(x.args.count, 1)
            XCTAssertEqual(x.args[0].name, "a")
            XCTAssertEqual(x.args[0].type, "Int")
            XCTAssertEqual(y.count, 6)
        }

        for currentLine in 2..<4 {
            let z = Parser(lines: lines, currentLine: currentLine, indent: "  ")
            let y = z.makeBlockComment()
            let x = z.funcMeta!

            XCTAssertEqual(x.name, "second")
            XCTAssertTrue(x.returnType.hasReturn)
            XCTAssertEqual(x.returnType.type, "String")
            XCTAssertEqual(x.args.count, 2)
            XCTAssertEqual(x.args[0].name, "b")
            XCTAssertEqual(x.args[0].type, "Int")
            XCTAssertEqual(x.args[1].name, "c")
            XCTAssertEqual(x.args[1].type, "Double")
            XCTAssertEqual(y.count, 7)
        }

        let z = Parser(lines: lines, currentLine: 4, indent: "  ")
        let y = z.makeBlockComment()
        XCTAssertEqual(y.count, 3)
    }

    func testReturnsDouble() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64?) -> ()) -> Double {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "Double")
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(x.args[1].type, "(Int64?) -> ()")
        XCTAssertEqual(y.count, 7)
    }

    func testReturnsArray() {
        let lines = ["static func save(to url: URL, blah: @escaping ([Int64]) -> ()) -> [Int] {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "[Int]")

        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(x.args[1].type, "([Int64]) -> ()")
        XCTAssertEqual(y.count, 7)
    }

    func testReturnsMap() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64, Boolean) -> ()) -> [Int:Int] {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "[Int:Int]")

        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(x.args[1].type, "(Int64, Boolean) -> ()")
        XCTAssertEqual(y.count, 7)
    }

    func testReturnsVoid() {
        let lines = ["static func save(to url: URL, blah: @escaping (Int64) -> ()) -> Void {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isNil)
        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")
        XCTAssertEqual(x.args[1].name, "blah")
        XCTAssertEqual(x.args[1].type, "(Int64) -> ()")
        XCTAssertEqual(y.count, 6)
    }

    func testReturnsNil() {
        let lines = ["static func save(to url: URL) -> nil {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isNil)

        XCTAssertEqual(x.args.count, 1)
        XCTAssertEqual(x.args[0].label, "to")
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")

        XCTAssertEqual(y.count, 5)
    }

    func testReturnsEmptyTuple() {
        let lines = ["static func save(url: URL) -> () {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isNil)

        XCTAssertEqual(x.args.count, 1)
        XCTAssertEqual(x.args[0].label, "url")
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")

        XCTAssertEqual(y.count, 5)
    }

    func testPrototype() {
        let lines = ["static func save(url: URL) -> ()"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        print(y)
        XCTAssertEqual(x.name, "save")
        XCTAssertTrue(x.returnType.isNil)
        XCTAssertEqual(x.args.count, 1)
        XCTAssertEqual(x.args[0].name, "url")
        XCTAssertEqual(x.args[0].type, "URL")

        XCTAssertEqual(y.count, 5)
    }

    func testDefaultArgument() {
        let lines = ["private init(timestampGenerator: TimestampGeneratorInterface = TimestampGenerator(), um: Int = 12, z: String? = nil) {\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: "  ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertEqual(x.name, "init")
        XCTAssertFalse(x.returnType.hasReturn)
        XCTAssertEqual(x.args.count, 3)
        XCTAssertEqual(x.args[0].name, "timestampGenerator")
        XCTAssertEqual(x.args[0].type, "TimestampGeneratorInterface")
        XCTAssertEqual(x.args[1].name, "um")
        XCTAssertEqual(x.args[1].type, "Int")
        XCTAssertEqual(x.args[2].name, "z")
        XCTAssertEqual(x.args[2].type, "String?")
        XCTAssertEqual(y.count, 7)
    }

    func testMinimal() {
        let lines = ["func a()\n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(x.name, "a")
        XCTAssertFalse(x.returnType.hasReturn)
        XCTAssertEqual(x.args.count, 0)
    }

    func testThrows() {
        let lines = ["func a()throws\n", "func a() throws\n", "func a() throws -> Double\n"]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertFalse(z.funcMeta!.returnType.hasReturn)

        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertFalse(z.funcMeta!.returnType.hasReturn)

        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertTrue(z.funcMeta!.returnType.hasReturn)
        XCTAssertFalse(z.funcMeta!.returnType.isNil)
    }

    func testGeneric() {
        let lines = ["func a<T: Blah where T.Element = Foo>   (          )     \n"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.name, "a<T: Blah where T.Element = Foo>")
        XCTAssertFalse(z.funcMeta!.returnType.hasReturn)
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

        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 0)
        XCTAssertEqual(z.funcMeta!.name, "init?")

        z = Parser(lines: lines, currentLine: 3, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 3)
        XCTAssertEqual(z.funcMeta!.name, "init")
    }

    func testSubscript() {
        let lines = ["subscript(index: Int) -> String {\n",
                     "subscript(_ index: Int) -> String {\n",
                     "subscript(row: Int, col: Int) -> Int {\n"
        ]
        var z = Parser(lines: lines, currentLine: 0, indent: " ")
        var y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 1)
        XCTAssertEqual(z.funcMeta!.args[0].name, "index")
        XCTAssertEqual(z.funcMeta!.name, "subscript")
        XCTAssertEqual(z.funcMeta!.returnType.type, "String")

        z = Parser(lines: lines, currentLine: 1, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 1)
        XCTAssertEqual(z.funcMeta!.args[0].name, "index")
        XCTAssertEqual(z.funcMeta!.name, "subscript")
        XCTAssertEqual(z.funcMeta!.returnType.type, "String")

        z = Parser(lines: lines, currentLine: 2, indent: " ")
        y = z.makeBlockComment()
        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(z.funcMeta!.args.count, 2)
        XCTAssertEqual(z.funcMeta!.args[0].name, "row")
        XCTAssertEqual(z.funcMeta!.name, "subscript")
        XCTAssertEqual(z.funcMeta!.returnType.type, "Int")
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
        let lines = ["let blah : (_ x: Int, _ y: Int)", " -> Int", "\n   "]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        _ = z.makeBlockComment()

        XCTAssertEqual(z.propertyMeta!.name, "blah")
        XCTAssertEqual(z.propertyMeta!.type, "(_ x: Int, _ y: Int) -> Int")
    }

    func testComplex3() {
        let lines = ["func application(_ application: UIApplication, didFinishLaunchingWithOptions",
                     " launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool ",
                     "{"]
        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(x.name, "application")
        XCTAssertTrue(x.returnType.hasReturn)
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "Bool")

        XCTAssertEqual(x.args.count, 2)
        XCTAssertEqual(x.args[0].name, "application")
        XCTAssertEqual(x.args[0].type, "UIApplication")
        XCTAssertEqual(x.args[1].label, "didFinishLaunchingWithOptions")
        XCTAssertEqual(x.args[1].name, "launchOptions")
        XCTAssertEqual(x.args[1].type, "[UIApplicationLaunchOptionsKey: Any]?")
    }

    func testTight() {
        let lines = ["    static func foo(a:Int)->Bool{return true}"]

        let z = Parser(lines: lines, currentLine: 0, indent: " ")
        let y = z.makeBlockComment()
        let x = z.funcMeta!

        XCTAssertTrue(y.count > 0)
        XCTAssertEqual(x.name, "foo")
        XCTAssertTrue(x.returnType.hasReturn)
        XCTAssertFalse(x.returnType.isNil)
        XCTAssertEqual(x.returnType.type, "Bool")

        XCTAssertEqual(x.args.count, 1)
        XCTAssertEqual(x.args[0].name, "a")
        XCTAssertEqual(x.args[0].type, "Int")
    }
}

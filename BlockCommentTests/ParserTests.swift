// Copyright © 2019 Brad Howes. All rights reserved.

import XCTest

class ParserTests: XCTestCase {
  
  func testLiteralParsing() {
    XCTAssertEqual(Parse.lit("1").parse("1"), "1")
    XCTAssertEqual(Parse.lit("12").parse("12"), "12")
    XCTAssertEqual(Parse.lit("1.23").parse("1.23"), "1.23")
    XCTAssertEqual(Parse.lit("foo").parse("  foo"), "foo")
    XCTAssertEqual(Parse.lit("bar", optional: true).parse("   bar  "), "bar")
    XCTAssertEqual(Parse.lit("bar", optional: true).parse("   "), "bar")
  }
  
  func testTupleParsing() {
    XCTAssertEqual(tupleType.parse("(Int, Int)"),  "(Int, Int)")
    XCTAssertEqual(tupleType.parse("(String, Boolean, (Int, Int))"), "(String, Boolean, (Int, Int))")
  }
  
  func testAttributeParsing() {
    XCTAssertEqual(attribute.parse("@objc fo"), "@objc")
    XCTAssertEqual(attribute.parse("@objc(one) foo"), "@objc")
    XCTAssertEqual(attribute.parse("@objc"), "@objc")
  }
  
  func testModifiersParsing() {
    let l1 = ["override private open", "static", "@objc"]
    XCTAssertEqual(modifiers.parse(Source(lines: l1, firstLine: 0)),
                   ["override", "private", "open", "static", "@objc"])
    XCTAssertEqual(modifiers.parse("@objc override   private   open func foo()"),
                   ["@objc", "override", "private", "open"])
  }
  
  func testArrayParsing() {
    XCTAssertEqual(arrayType.parse("[ [ Int ]]"), "[ [ Int ]]")
    XCTAssertEqual(arrayType.parse("[ Int ]]"), "[ Int ]")
  }
  
  func testReturnTypeParsing() {
    XCTAssertEqual(returnType.parse("-> Void"), "Void")
    XCTAssertEqual(returnType.parse("-> Int"), "Int")
    XCTAssertEqual(returnType.parse("-> ()"), "()")
    XCTAssertEqual(returnType.parse("-> (String, Double, (Int, Int))"), "(String, Double, (Int, Int))")
  }
  
  func testClosureParsing() {
    XCTAssertEqual(function.parse("(Int) -> Void"), "(Int)->Void")
    XCTAssertEqual(function.parse("(Int, Double) -> Void"), "(Int, Double)->Void")
    XCTAssertEqual(function.parse("(Int, Double) -> ()"), "(Int, Double)->()")
    XCTAssertEqual(function.parse("(Int, Double) -> (String, Boolean, (Int, Int))"),
                   "(Int, Double)->(String, Boolean, (Int, Int))")
  }
  
  func testTypeParser() {
    XCTAssertEqual(Type.parser.parse("(Int) -> Void"), Type(spec: "(Int)->Void", opt: false))
    XCTAssertEqual(Type.parser.parse("(Int, String) ->  Double"), Type(spec: "(Int, String)->Double", opt: false))
    XCTAssertEqual(Type.parser.parse("Void"), Type(spec: "Void", opt: false))
    XCTAssertEqual(Type.parser.parse("Int"), Type(spec: "Int", opt: false))
    XCTAssertEqual(Type.parser.parse("Int?"), Type(spec: "Int", opt: true))
    XCTAssertEqual(Type.parser.parse("[Blah]"), Type(spec: "[Blah]", opt: false))
    XCTAssertEqual(Type.parser.parse("[Blah]?"), Type(spec: "[Blah]", opt: true))
    XCTAssertEqual(Type.parser.parse("(Int, Foo)"), Type(spec: "(Int, Foo)", opt: false))
    XCTAssertEqual(Type.parser.parse("(Int, Foo)?"), Type(spec: "(Int, Foo)", opt: true))
    XCTAssertEqual(Type.parser.parse("Foo<Bar>?"), Type(spec: "Foo", opt: true))
    XCTAssertEqual(Type.parser.parse("Foo.Bar<Beep>?"), Type(spec: "Foo.Bar", opt: true))
  }
  
  func testClosureValueParsing() {
    XCTAssertEqual(closureValue.parse("{ return 1 }   "), "{ return 1 }")
    XCTAssertEqual(closureValue.parse("{ return { (a: Int, b: Int) -> Int in return a * b } }"),
                   "{ return { (a: Int, b: Int) -> Int in return a * b } }")
  }
  
  func testStringParsing() {
    XCTAssertEqual(string.parse("\"this is a \\\"test\\\"\""), "\"this is a \\\"test\\\"\"")
  }
  
  func testDefaultValueParsing() {
    XCTAssertEqual(defaultValue.parse("=123"), true)
    XCTAssertEqual(defaultValue.parse(" = true"), true)
    XCTAssertEqual(defaultValue.parse(" = 1.23"), true)
    XCTAssertEqual(defaultValue.parse("""
                = "testing",
"""
                                     ), true)
  }
  
  func testArgModsTypeParsing() {
    XCTAssertEqual(argMods.parse(""), [])
    XCTAssertEqual(argMods.parse("inout"), ["inout"])
    XCTAssertEqual(argMods.parse("@escaping"), ["@escaping"])
    XCTAssertEqual(argMods.parse("@autoclosure @escaping"), ["@autoclosure", "@escaping"])
    XCTAssertEqual(argMods.parse("@escaping (Int)->Void"), ["@escaping"])
  }
  
  func testArgTypeParsing() {
    XCTAssertEqual(argType.parse("Int"), Type(spec: "Int", opt: false))
    XCTAssertEqual(argType.parse("inout Int"), Type(spec: "Int", opt: false))
    XCTAssertEqual(argType.parse("inout @escaping Int? = 123"), Type(spec: "Int", opt: true))
    XCTAssertEqual(argType.parse("(Int) -> Void"), Type(spec: "(Int)->Void", opt: false))
    XCTAssertEqual(argType.parse("@escaping (Int) -> Void"), Type(spec: "(Int)->Void", opt: false))
    XCTAssertEqual(argType.parse("@objc(blah) (Int) -> Void"), Type(spec: "(Int)->Void", opt: false))
  }
  
  func testArgTypeParsingWithAttribute() {
    XCTAssertEqual(argType.parse("@escaping (Int)->Void"), Type(spec: "(Int)->Void", opt: false))
  }
  
  func testArgumentParser() {
    XCTAssertEqual(Argument.parser.parse("z: Abc"),
                   Argument(name: "z", type: Type(spec: "Abc", opt: false), hasDefault: false))
    XCTAssertEqual(Argument.parser.parse("one two   : Foo?"),
                   Argument(name: "two", type: Type(spec: "Foo", opt: true), hasDefault: false))
    XCTAssertEqual(Argument.parser.parse("_ abc: Int = 123"),
                   Argument(name: "abc", type: Type(spec: "Int", opt: false), hasDefault: true))
    XCTAssertEqual(Argument.parser.parse("_ factor: CGFloat = 1.25"),
                   Argument(name: "factor", type: Type(spec: "CGFloat", opt: false), hasDefault: true))
  }
  
  func testArgumentsParsing() {
    XCTAssertTrue(arguments.parse("")!.isEmpty)
    XCTAssertEqual(arguments.parse("_ a: Int, _ b: String, c: Double")!.count, 3)
  }
  
  func testFunctionParser_Minimal() {
    XCTAssertEqual(Function.parser.parse("func foo()"),
                   Function(name: "foo", args:[], throwable: false, returns: nil))
    XCTAssertTrue(Function.parser.parse("static func f(a:Int)->Bool{return true}") != nil)
  }
  
  func testFunctionParser_Throws() {
    XCTAssertEqual(Function.parser.parse("func foo() throws"),
                   Function(name: "foo", args:[], throwable: true, returns: nil))
  }
  
  func testFunctionParser_Returns() {
    XCTAssertEqual(Function.parser.parse("func foo() -> Int"),
                   Function(name: "foo", args: [], throwable: false, returns: "Int"))
  }
  
  func testFunctionParser_ThrowsAndReturns() {
    XCTAssertEqual(Function.parser.parse("func foo() throws -> Int"),
                   Function(name: "foo", args: [], throwable: true, returns: "Int"))
  }
  
  
  func testFunctionParser_VoidNoReturn() {
    XCTAssertEqual(Function.parser.parse("func foo() throws -> Void"),
                   Function(name: "foo", args: [], throwable: true, returns: nil))
    XCTAssertEqual(Function.parser.parse("func foo() throws -> ()"),
                   Function(name: "foo", args: [], throwable: true, returns: nil))
  }
  
  func testFunctionParser_Inits() {
    XCTAssertEqual(Function.parser.parse("init()"),
                   Function(name: "init", args: [], throwable: false, returns: nil))
    XCTAssertEqual(Function.parser.parse("required init?()"),
                   Function(name: "init?", args: [], throwable: false, returns: nil))
    XCTAssertEqual(Function.parser.parse("init?(_ a: Int)"),
                   Function(name: "init?", args: [Argument(name: "a", type: Type(spec: "Int", opt: false),
                                                           hasDefault: false)],
                            throwable: false, returns: nil))
  }
  
  func testFunctionParser_Complex1() {
    let lines = [
      "   @discardableResult",
      "   override",
      "        private open",
      " func comp김lex(   a: inout ",
      "     @escaping Int, b c : Foo? = 121 ) throws -> (four: Int,",
      "five: (six: Int, seven: Int)) "
    ]
    XCTAssertEqual(Function.parser.parse(Source(lines: lines, firstLine: 0)),
                   Function(name: "comp김lex",
                            args: [
                              Argument(name: "a", type: Type(spec: "Int", opt: false), hasDefault: false),
                              Argument(name: "c", type: Type(spec: "Foo", opt: true), hasDefault: true)],
                            throwable: true, returns: "(four: Int, five: (six: Int, seven: Int))"))
  }
  
  func testFunctionParser_Complex2() {
    let complex = """
        override internal \t\tfunc \tcomp김lex   (_ a김: inout
        Int, o23김 b: (one: Int, two:
        Int, three: Int), cc김 c김: inout Double) throws
        -> (four: Int, five: \t\t(six: Int, seven: Int))
        """
    let tmp = Function.parser.parse(complex)
    XCTAssertTrue(tmp != nil)
    XCTAssertEqual(tmp?.name, "comp김lex")
    XCTAssertEqual(tmp?.args.count, 3)
    XCTAssertEqual(tmp?.throwable, true)
    XCTAssertEqual(tmp?.returns, "(four: Int, five: \t\t(six: Int, seven: Int))")
  }
  
  func testFunction_Operator() {
    let lines = [ "", "public static func == (lhs: LegacyFavorite, rhs: LegacyFavorite) -> Bool", ""]
    let tmp = Function.parser.parse(Source(lines: lines, firstLine: 1))
    XCTAssertTrue(tmp != nil)
    XCTAssertEqual(tmp?.name, "==")
  }
  
  func testFunction_Mutating() {
    let lines = [ "", "    public mutating func post(to sampler: Sampler) {", ""]
    let tmp = Function.parser.parse(Source(lines: lines, firstLine: 1))
    XCTAssertTrue(tmp != nil)
    XCTAssertEqual(tmp?.name, "post")
  }
  
  func testFunctionParser_ClosureArg() {
    XCTAssertTrue(Function.parser.parse("func f(c: (Int) -> Void)") != nil)
  }
  
  func testFunctionParser_OptionalArg() {
    XCTAssertTrue(Function.parser.parse("""
                func application(_ application: UIApplication, didFinishLaunchingWithOptions
                launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
                """
                                       ) != nil)
  }
  
  func testFunctionParser_TemplateArg() {
    XCTAssertEqual(Function.parser.parse("func a<T: Blah where (T.Element = Foo)>   (          )     ")!.name, "a")
    XCTAssertEqual(Function.parser.parse("func a <T: Blah where T.Element = Foo>   (          )     ")!.name, "a")
  }
  
  func testFunctionParser_WhereClause() {
    XCTAssertEqual(Function.parser.parse("""
        func allItemsMatch<C1: Container, C2: Container>
            (_ someContainer: C1, _ anotherContainer: C2) -> Bool
            where C1.Item == C2.Item, C1.Item: Equatable
"""), Function(name: "allItemsMatch",
               args: [Argument(name: "someContainer", type: Type(spec: "C1", opt: false), hasDefault: false),
                      Argument(name: "anotherContainer", type: Type(spec: "C2", opt: false), hasDefault: false)],
               throwable: false, returns: "Bool"))
  }
  
  func testFunctionParser_DefaultClosure() {
    XCTAssertTrue(Function.parser.parse("func fetch(in a: B, c: (Foo<Self>) -> () = { _ in }) -> [Self] {") != nil)
  }
  
  func testContainerParser() {
    XCTAssertEqual(Container.parser.parse("public struct Blah {"),
                   Container(kind: .struct, name: "Blah", inherits: nil))
    XCTAssertEqual(Container.parser.parse("public class Blah: Foo {"),
                   Container(kind: .class, name: "Blah", inherits: "Foo"))
    XCTAssertEqual(Container.parser.parse("public final class Beep: Boop {"),
                   Container(kind: .class, name: "Beep", inherits: "Boop"))
    XCTAssertEqual(Container.parser.parse("final public class Beep: Boop {"),
                   Container(kind: .class, name: "Beep", inherits: "Boop"))
    XCTAssertEqual(Container.parser.parse("public enum Blah: Int {"),
                   Container(kind: .enum, name: "Blah", inherits: "Int"))
    XCTAssertEqual(Container.parser.parse("protocol Blah: class {"),
                   Container(kind: .protocol, name: "Blah", inherits: "class"))
  }
  
  func testPropertyParser() {
    XCTAssertEqual(Property.parser.parse("private let foo: Int"), Property(kind: .let, name: "foo"))
    XCTAssertEqual(Property.parser.parse("let foo = 3"), Property(kind: .let, name: "foo"))
    XCTAssertEqual(Property.parser.parse("var foo: Int"), Property(kind: .var, name: "foo"))
    XCTAssertEqual(Property.parser.parse("lazy var foo: Int = { 1 * 3 }()"), Property(kind: .var, name: "foo"))
    XCTAssertEqual(Property.parser.parse("@objc public private(set) lazy var foo: Int = { 1 * 3 }()"),
                   Property(kind: .var, name: "foo"))
    XCTAssertEqual(Property.parser.parse("public typealias Element = Int"),
                   Property(kind: .typealias, name: "Element"))
    XCTAssertEqual(Property.parser.parse("associatedtype Element"),
                   Property(kind: .associatedtype, name: "Element"))
  }
  
  func testCommentable_Property() {
    let comment = commentable.parse("    @objc private let foo: Int = 3")!
    XCTAssertEqual(comment.count, 1)
    let line = comment[0]
    XCTAssertEqual(line, "/// <#Describe foo#>")
  }
  
  func testCommentable_Container() {
    let comment = commentable.parse(" @objc struct Foo: Bar {")!
    XCTAssertEqual(comment.count, 4)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " <#Describe Foo#>")
    XCTAssertEqual(comment[2], " - SeeAlso: `Bar`")
    XCTAssertEqual(comment[3], " */")
  }
  
  func testCommentable_FunctionNoReturnNoArgs() {
    let comment = commentable.parse("  func play<A>() {")!
    XCTAssertEqual(comment.count, 3)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " <#Describe play#>")
    XCTAssertEqual(comment[2], " */")
  }
  func testCommentable_FunctionThrows() {
    let comment = commentable.parse("  func play<A>() throws {")!
    XCTAssertEqual(comment.count, 5)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " <#Describe play#>")
    XCTAssertEqual(comment[2], "")
    XCTAssertEqual(comment[3], " - throws <#Describe exceptions#>")
    XCTAssertEqual(comment[4], " */")
  }
  
  func testCommentable_FunctionThrowsAndReturns() {
    let comment = commentable.parse("  func play<A>() throws    -> Int {")!
    XCTAssertEqual(comment.count, 6)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " <#Describe play#>")
    XCTAssertEqual(comment[2], "")
    XCTAssertEqual(comment[3], " - returns: <#Int#>")
    XCTAssertEqual(comment[4], " - throws <#Describe exceptions#>")
    XCTAssertEqual(comment[5], " */")
  }
  
  func testCommentable_FunctionArgsThrowsAndReturns() {
    let comment = commentable.parse("  func play<A>(_ a: Int, b bb: King) throws    -> Int {")!
    XCTAssertEqual(comment.count, 8)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " <#Describe play#>")
    XCTAssertEqual(comment[2], "")
    XCTAssertEqual(comment[3], " - parameter a: <#Describe a#>")
    XCTAssertEqual(comment[4], " - parameter bb: <#Describe bb#>")
    XCTAssertEqual(comment[5], " - returns: <#Int#>")
    XCTAssertEqual(comment[6], " - throws <#Describe exceptions#>")
    XCTAssertEqual(comment[7], " */")
  }
  
  func testCommentable_Default() {
    let comment = commentable.parse("  this is a sillly test")!
    XCTAssertEqual(comment.count, 1)
    XCTAssertEqual(comment[0], "/// ")
  }
  
  func testParse() {
    let lines = ["// line", "  func one(two: Three)", "-> Four ", "       {"]
    let comment = parse(source: Source(lines: lines, firstLine: 1))
    XCTAssertEqual(comment.count, 6)
    XCTAssertEqual(comment[0], "  /**")
    XCTAssertEqual(comment[1], "   \("Describe one".tagged)")
    XCTAssertEqual(comment[2], "  ")
    XCTAssertEqual(comment[3], "   - parameter two: \("Describe two".tagged)")
    XCTAssertEqual(comment[4], "   - returns: \("Four".tagged)")
    XCTAssertEqual(comment[5], "   */")
  }
  
  //    @objc dynamic func handleGesture(_ panner: UIPanGestureRecognizer) {
  func testParse2() {
    let lines = ["@objc dynamic func handleGesture(_ panner: UIPanGestureRecognizer) {"]
    let comment = parse(source: Source(lines: lines, firstLine: 0))
    XCTAssertEqual(comment.count, 5)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " \("Describe handleGesture".tagged)")
    XCTAssertEqual(comment[2], "")
    XCTAssertEqual(comment[3], " - parameter panner: \("Describe panner".tagged)")
    XCTAssertEqual(comment[4], " */")
  }

  // public init(inApp: Bool, suiteName: String = Settings.defaultSuiteName, identity: Int? = nil) {
  func testParse3() {
    let lines = ["public init(inApp: Bool, suiteName: String = Settings.defaultSuiteName, identity: Int? = nil) {"]
    let comment = parse(source: Source(lines: lines, firstLine: 0))
    XCTAssertEqual(comment.count, 7)
    XCTAssertEqual(comment[0], "/**")
    XCTAssertEqual(comment[1], " \("Describe init".tagged)")
    XCTAssertEqual(comment[2], "")
    XCTAssertEqual(comment[3], " - parameter inApp: \("Describe inApp".tagged)")
    XCTAssertEqual(comment[4], " - parameter suiteName: \("Describe suiteName".tagged)")
    XCTAssertEqual(comment[5], " - parameter identity: \("Describe identity".tagged)")
    XCTAssertEqual(comment[6], " */")
  }
}

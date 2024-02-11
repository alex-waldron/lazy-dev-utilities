import XCTest
@testable import PropertyMappable

final class PropertyMappableTests: XCTestCase {
    func testSourceToOther() {
        var t = Test(val: "Hey")
        let other = TestOther(val: "Yo")

        t.update(using: other)
        XCTAssertEqual(t.val, "Yo")
    }

    func testOtherToSource() {
        var other = TestOther(val: "hi")
        let test = Test(val: "yerd")

        other.update(using: test)
        XCTAssertEqual(other.val, "yerd")
    }

    func testSubLevelSourceToOther() {
        var t = Test(val: "Hey", subVal: SubTest(prop: "123"))
        let other = TestOther(val: "Hey", subVal: SubTestOther(prop: "456"))
        t.update(using: other)

        XCTAssertEqual(t.subVal?.prop, "456")
    }

    func testSubLevelOtherToSource() {
        var other = TestOther(val: "hi", subVal: SubTestOther(prop: "987"))
        let test = Test(val: "hi", subVal: SubTest(prop: "654"))

        other.update(using: test)
        XCTAssertEqual(other.subVal?.prop, "654")
    }
}

private struct Test: PropertyMappable {

    typealias OtherMappable = TestOther

    var val: String
    var subVal: SubTest?

    static var propertyMappings: PropertyMapperCollection {
        (\.val, \.val)
        (\.subVal, \.subVal)
    }
}

private struct TestOther: PropertyMappable {
    typealias OtherMappable = Test

    var val: String
    var subVal: SubTestOther?
}

private struct SubTest: PropertyMappable {
    typealias OtherMappable = SubTestOther

    static var propertyMappings: PropertyMapperCollection {
        (\.prop, \.prop)
    }

    var prop: String

}

private struct SubTestOther: PropertyMappable {
    typealias OtherMappable = SubTest
    
    var prop: String
}

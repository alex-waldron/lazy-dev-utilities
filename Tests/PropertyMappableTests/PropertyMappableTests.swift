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
        let other = TestOther(val: "Hey", subVal: SubTestInfo(prop: "456"))
        t.update(using: other)

        XCTAssertEqual(t.subVal?.prop, "456")
    }

    func testSubLevelOtherToSource() {
        var other = TestOther(val: "hi", subVal: SubTestInfo(prop: "987"))
        let test = Test(val: "hi", subVal: SubTest(prop: "654"))

        other.update(using: test)
        XCTAssertEqual(other.subVal?.prop, "654")
    }
}

private struct Test: PropertyMappable {

    typealias Info = TestOther

    var val: String
    var subVal: SubTest?

    static var kps: KeyPathCollection {
        (\.val, \.val)
        (\.subVal, \.subVal)
    }
}

private struct TestOther: MirrorableInfo {
    typealias Source = Test

    var val: String
    var subVal: SubTestInfo?
}

private struct SubTest: PropertyMappable {
    typealias Info = SubTestInfo

    static var kps: KeyPathCollection {
        (\.prop, \.prop)
    }

    var prop: String

}

private struct SubTestInfo: MirrorableInfo {
    typealias Source = SubTest
    var prop: String
}

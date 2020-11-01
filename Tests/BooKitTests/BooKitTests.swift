import XCTest
@testable import BooKit

final class BooKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BooKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

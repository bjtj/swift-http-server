import XCTest
@testable import swift_http_server

final class swift_http_serverTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_http_server().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

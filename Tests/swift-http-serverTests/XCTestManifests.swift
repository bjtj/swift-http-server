import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(HttpHeaderTests.allTests),
      testCase(ReadTests.allTests),
      testCase(RouterTests.allTests),
      testCase(swift_http_serverTests.allTests),
    ]
}
#endif

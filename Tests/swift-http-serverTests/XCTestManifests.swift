import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(URLParsePathTests.allTests),
      testCase(HttpHeaderTests.allTests),
      testCase(RouterTests.allTests),
      testCase(swift_http_serverTests.allTests),
    ]
}
#endif

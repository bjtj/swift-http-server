import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(ReadTests.allTests),
      testCase(swift_http_serverTests.allTests),
      testCase(RouterTests.allTests),
    ]
}
#endif

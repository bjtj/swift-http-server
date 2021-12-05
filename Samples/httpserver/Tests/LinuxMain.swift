import XCTest

import httpserverTests

var tests = [XCTestCaseEntry]()
tests += httpserverTests.allTests()
XCTMain(tests)
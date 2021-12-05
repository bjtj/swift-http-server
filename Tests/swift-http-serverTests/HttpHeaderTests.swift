import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket

final class HttpHeaderTests: XCTestCase {

    // TEST -- Http Header
    func testHttpHeader() throws {
        let text = "GET / HTTP/1.1\r\nLocation: http://example.com\r\nExt: \r\n\r\n"
        let header = try HttpHeader.read(text: text)
        XCTAssertEqual(header.description, text)
    }

    // TEST -- Http Header Reader
    func testHttpHeaderReader() throws {
        let text = "GET / HTTP/1.1\r\nLocation: http://example.com\r\nExt: \r\n\r\n"

        var str = text[..<text.index(text.startIndex, offsetBy: 20)]

        if str.hasSuffix("\r\n\r\n") {
            let header = try HttpHeader.read(text: text)
            XCTAssertEqual(header.description, text)
        }

        str += text[text.index(text.startIndex, offsetBy: 20)...]
        
        if str.hasSuffix("\r\n\r\n") {
            let header = try HttpHeader.read(text: text)
            XCTAssertEqual(header.description, text)
        } else {
            XCTAssert(false)
        }
    }

    static var allTests = [
      ("testHttpHeader", testHttpHeader),
      ("testHttpHeaderReader", testHttpHeaderReader),
    ]

}

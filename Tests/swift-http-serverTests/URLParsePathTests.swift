import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket

final class URLParsePathTests: XCTestCase {

    // TEST -- Parse Path
    func testParsePath() {

        do {
            let path = "/"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.queryString, nil)
            XCTAssertEqual(parser.countAllQueryParameters, 0)
            XCTAssertEqual(parser.countAllPathParameters, 0)
            XCTAssertNil(parser.parameter("param1", of: .pathParameter))
            XCTAssertNil(parser.parameters("param1", of: .pathParameter))
        }

        do {
            let path = "/?k=&k2=???&k3="
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 3)
            XCTAssertEqual(parser.parameter("k"), "")
            XCTAssertEqual(parser.parameter("k2"), "???")
            XCTAssertEqual(parser.parameter("k3"), "")
            XCTAssertEqual(path, parser.description)
        }

        do {
            let path = "/path/to/file;seg1=seg-value1;seg2=x?key1=value1&key1=value2&key2=valuex#fragment"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/path/to/file")
            XCTAssertEqual(parser.queryString, "key1=value1&key1=value2&key2=valuex")
            XCTAssertEqual(parser.pathParameterString, "seg1=seg-value1;seg2=x")
            XCTAssertEqual(parser.fragmentString, "fragment")
            XCTAssertEqual(parser.countAllQueryParameters, 3)
            XCTAssertEqual(parser.countAllPathParameters, 2)
            XCTAssertEqual(parser.parameter("key1"), "value1")
            XCTAssertEqual(parser.parameters("key1"), ["value1", "value2"])
            XCTAssertEqual(parser.parameter("key2"), "valuex")
            XCTAssertEqual(parser.parameter("seg1", of: .pathParameter), "seg-value1")
            XCTAssertEqual(path, parser.description)
        }

        do {
            let path = "/path/to/?k=&k2"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/path/to/")
            XCTAssertEqual(parser.countAllQueryParameters, 2)
            XCTAssertEqual(parser.parameter("k"), "")
            XCTAssertEqual(parser.parameter("k2"), "")
            XCTAssertEqual("/path/to/?k=&k2=", parser.description)
        }

        do {
            let path = "/?k&k2="
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 2)
            XCTAssertEqual(parser.parameter("k"), "")
            XCTAssertEqual(parser.parameter("k2"), "")
            XCTAssertEqual("/?k=&k2=", parser.description)
        }

        do {
            let path = "/?k&k2=&k"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 3)
            XCTAssertEqual(parser.parameter("k"), "")
            XCTAssertEqual(parser.parameters("k"), ["", ""])
            XCTAssertEqual(parser.parameter("k2"), "")
            XCTAssertEqual("/?k=&k=&k2=", parser.description)
        }

        do {
            let path = "/?&&&"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 0)
            XCTAssertEqual("/", parser.description)
        }

        do {
            let path = "/?&a&&"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 1)
            XCTAssertEqual(parser.keys(of: .queryParameter), ["a"])
            XCTAssertEqual("/?a=", parser.description)
        }

        do {
            let path = "/?&a&&"
            let parser = helperParsePath(string: path)
            XCTAssertEqual(parser.path, "/")
            XCTAssertEqual(parser.countAllQueryParameters, 1)
            XCTAssertEqual(parser.keys(of: .queryParameter), ["a"])
            XCTAssertEqual("/?a=", parser.description)

            parser.path = "/newpath"
            parser.setParameter("name", "tj")
            parser.setParameter("greet", "hello")

            XCTAssertEqual("/newpath?a=&name=tj&greet=hello", parser.description)

            parser.removeParameter("greet")

            XCTAssertEqual("/newpath?a=&name=tj", parser.description)

            parser.removeParameter("a")

            XCTAssertEqual("/newpath?name=tj", parser.description)

            parser.fragment = "top"

            XCTAssertEqual("/newpath?name=tj#top", parser.description)

            parser.fragment = nil

            XCTAssertEqual("/newpath?name=tj", parser.description)
        }
        
    }

    func helperParsePath(string: String) -> URLPathParser {
        return URLPathParser(string: string)
    }

    static var allTests = [
      ("testParsePath", testParsePath),
    ]

}

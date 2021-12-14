import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class RouterTests: XCTestCase {

    func testRoute() {

        do {
            
            var router = HttpServerRouter()

            class MyHandler: HttpRequestHandler {

                let responseBody: String
                
                init(responseBody: String) {
                    self.responseBody = responseBody
                }

                var dumpBody: Bool = true
                
                func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
                }
                
                func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                    response.status = .ok
                    response.data = responseBody.data(using: .utf8)
                }
            }

            try router.register(pattern: "/", handler: MyHandler(responseBody: "/"))
            try router.register(pattern: "/abc/def", handler: MyHandler(responseBody: "/abc/def"))
            try router.register(pattern: "/abc", handler: MyHandler(responseBody: "/abc"))

            XCTAssertNotNil(router.dispatch(path: "/"))
            XCTAssertEqual((router.dispatch(path: "/") as? MyHandler)?.responseBody, "/")
            XCTAssertNotNil(router.dispatch(path: "/abc/def"))
            XCTAssertEqual((router.dispatch(path: "/abc/def") as? MyHandler)?.responseBody, "/abc/def")
            XCTAssertNotNil(router.dispatch(path: "/abc"))
            XCTAssertEqual((router.dispatch(path: "/abc") as? MyHandler)?.responseBody, "/abc")
            XCTAssertNil(router.dispatch(path: "/abcd"))

            // ---------------------------------

            router = HttpServerRouter()
            
            try router.register(pattern: "/**", handler: MyHandler(responseBody: "/**"))

            XCTAssertNotNil(router.dispatch(path: "/"))
            XCTAssertNotNil(router.dispatch(path: "/abc/"))
            XCTAssertNotNil(router.dispatch(path: "/xyz/abc"))
            XCTAssertNotNil(router.dispatch(path: "/xyz/abc/def"))
            XCTAssertNotNil(router.dispatch(path: "/xyz"))

            // ---------------------------------

            router = HttpServerRouter()
            
            try router.register(pattern: "/xyz/**", handler: MyHandler(responseBody: "/xyz/**"))

            XCTAssertNotNil(router.dispatch(path: "/xyz/"))
            XCTAssertNotNil(router.dispatch(path: "/xyz/abc"))
            XCTAssertNotNil(router.dispatch(path: "/xyz/abc/def"))
            XCTAssertNil(router.dispatch(path: "/xyz"))
            XCTAssertNil(router.dispatch(path: "/abc"))

            // ---------------------------------

            router = HttpServerRouter()
            
            try router.register(pattern: "/xyz/**/123", handler: MyHandler(responseBody: "/xyz/**/123"))

            XCTAssertNotNil(router.dispatch(path: "/xyz/aaaaa/123"))
            XCTAssertNotNil(router.dispatch(path: "/xyz/ab/123"))
            XCTAssertNotNil(router.dispatch(path: "/xyz//123"))
            XCTAssertNil(router.dispatch(path: "/xyz/123"))
            XCTAssertNil(router.dispatch(path: "/xyz"))
            XCTAssertNil(router.dispatch(path: "/123"))
            XCTAssertNil(router.dispatch(path: "/xyz/1234"))
            XCTAssertNil(router.dispatch(path: "/xyz/123/"))

            do {
                try router.register(pattern: "/xyz/**/123/**", handler: MyHandler(responseBody: "FAIL!"))
                XCTFail("Must be failed")
            } catch let error as HttpServerError {
                switch error {
                    case .custom(let string):
                        XCTAssertTrue(string.contains("**"))
                    default:
                        XCTFail("not expected error - \(error)")
                }
            }

            do {
                try router.register(pattern: "", handler: MyHandler(responseBody: "FAIL!"))
                XCTFail("Must be failed")
            } catch let error as HttpServerError {
                switch error {
                    case .custom(let string):
                        XCTAssertTrue(string.contains("Empty"))
                    default:
                        XCTFail("not expected error - \(error)")
                }
            }

            do {
                try router.register(pattern: "abc", handler: MyHandler(responseBody: "FAIL!"))
                XCTFail("Must be failed")
            } catch let error as HttpServerError {
                switch error {
                    case .custom(let string):
                        XCTAssertTrue(string.contains("not start with /"))
                    default:
                        XCTFail("not expected error - \(error)")
                }
            }


            // ---------------------------------

            router = HttpServerRouter()
            
            try router.register(pattern: "/**", handler: MyHandler(responseBody: "/**"))
            try router.register(pattern: "/abc/**", handler: MyHandler(responseBody: "/abc/**"))
            try router.register(pattern: "/abc/def", handler: MyHandler(responseBody: "/abc/def"))
            try router.register(pattern: "/abc", handler: MyHandler(responseBody: "/abc"))

            print(router.table.map { "'\($0.pattern)' depth: \($0.depth)" })

            XCTAssertEqual((router.dispatch(path: "/") as? MyHandler)?.responseBody, "/**")
            XCTAssertEqual((router.dispatch(path: "/abc") as? MyHandler)?.responseBody, "/abc")
            XCTAssertEqual((router.dispatch(path: "/abc/def") as? MyHandler)?.responseBody, "/abc/def")
            XCTAssertEqual((router.dispatch(path: "/abc/def/x") as? MyHandler)?.responseBody, "/abc/**")
            
        } catch let err {
            XCTFail("unexpected error: \(err)")
        }
    }
    
    public static var allTests = [
      ("testRoute", testRoute),
    ]
}

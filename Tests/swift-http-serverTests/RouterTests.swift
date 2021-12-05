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
            
        } catch let err {
            XCTFail("unexpected error: \(err)")
        }

    }
    

    public static var allTests = [
      ("testRoute", testRoute),
    ]
}

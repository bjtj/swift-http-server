import XCTest
@testable import swift_http_server

final class swift_http_serverTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_http_server().text, "Hello, World!")
    }

    func testHttpHeader() {
        let text = "GET / HTTP/1.1\r\nLocation: http://example.com\r\nExt: \r\n\r\n"
        let header = HttpHeader.read(text: text)
        XCTAssertEqual(header.description, text)
    }

    func testHttpHeaderReader() {
        let text = "GET / HTTP/1.1\r\nLocation: http://example.com\r\nExt: \r\n\r\n"

        var str = text[..<text.index(text.startIndex, offsetBy: 20)]

        if str.hasSuffix("\r\n\r\n") {
            let header = HttpHeader.read(text: text)
            XCTAssertEqual(header.description, text)
        }

        str += text[text.index(text.startIndex, offsetBy: 20)...]
        
        if str.hasSuffix("\r\n\r\n") {
            let header = HttpHeader.read(text: text)
            XCTAssertEqual(header.description, text)
        } else {
            XCTAssert(false)
        }
    }

    func testHttpServer() {
        let server = HttpServer(port: 0)
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            do {
                try server.run()
            } catch {
            }
        }

        sleep(1)

        let req = URLRequest(url: URL(string: "http://localhost:\((server.serverAddress.1)!)")!)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("error: \(error!)")
                return
            }
            guard let _data = data else {
                print("error: no response data")
                return
            }

            print(String(data: _data, encoding: .utf8)!)
        }
        task.resume()

        sleep(1)

        server.finish()

        sleep(1)
    }

    func testTransfer() {
        // fixed size
        // chunked

        let data = Data()
        let inputStream = InputStream(data: "5\r\nhello6\r\n world0\r\n".data(using: .utf8)!)
        let transfer = ChunkedTransfer(inputStream: inputStream)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 10)
        let readSize = transfer.read(buffer, maxLength: 10)
        if readSize > 0 {
            print(String(data: data, encoding: .utf8)!)
        }
    }

    func testKeepConnect() {

        let _ = HttpHeader()
        
        // Connection: keep-alive
        // Connection: close
    }

    func testRoute() {
        var _ = Router()
    }

    static var allTests = [
      ("testExample", testExample),
      ("testHttpHeader", testHttpHeader),
      ("testHttpHeaderReader", testHttpHeaderReader),
      ("testHttpServer", testHttpServer),
      ("testTransfer", testTransfer),
      ("testKeepConnect", testKeepConnect),
      ("testRoute", testRoute),
    ]
}

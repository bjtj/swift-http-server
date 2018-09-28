import XCTest
@testable import SwiftHttpServer

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

    func testHttpServer() throws {
        let server = HttpServer(port: 0)
        try server.route(pattern: "/") {
            (request) in
            let response = HttpResponse(code: 200, reason: HttpStatusCode.shared[200])
            response.data = "Hello".data(using: .utf8)
            return response
        }
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            do {
                try server.run()
            } catch let error {
                print(error)
            }
        }

        sleep(1)

        guard let address = server.serverAddress else {
            XCTAssert(false)
            return
        }

        let req = URLRequest(url: URL(string: "http://localhost:\(address.port)")!)
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

    func testChunkedTransfer() {
        // fixed size
        // chunked

        let inputStream = InputStream(data: "5\r\nhello6\r\n world0\r\n".data(using: .utf8)!)
        let transfer = ChunkedTransfer(inputStream: inputStream)

        inputStream.open()

        XCTAssertEqual(try transfer.readChunkSize(), 5)
        XCTAssertEqual(try transfer.readChunkData(chunkSize: 5), "hello".data(using: .utf8))
        // XCTAssertEqual(try transfer.readChunkSize(), 6)
        // XCTAssertEqual(try transfer.readChunkData(chunkSize: 6), " world".data(using: .utf8))
        // XCTAssertEqual(try transfer.readChunkSize(), 0)

        let bufferSize = 10
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        XCTAssertEqual(transfer.read(buffer, maxLength: bufferSize), 6)
        XCTAssertEqual(String(cString: buffer), " world")

        XCTAssertEqual(transfer.read(buffer, maxLength: bufferSize), 0)
    }

    func testKeepConnect() {

        let header = HttpHeader()

        header.firstLine = FirstLine.read(text: "HTTP/1.0 200 OK")

        XCTAssertEqual(header.connectionType, nil)
        XCTAssertEqual(false, requiredKeepConnect(specVersion: header.firstLine.first, header: header))

        header["Connection"] = "close"
        XCTAssertEqual(header.connectionType, .close)
        XCTAssertEqual(false, requiredKeepConnect(specVersion: header.firstLine.first, header: header))

        header["Connection"] = "keep-alive"
        XCTAssertEqual(header.connectionType, .keep_alive)
        XCTAssertEqual(true, requiredKeepConnect(specVersion: header.firstLine.first, header: header))

        header.firstLine = FirstLine.read(text: "HTTP/1.1 200 OK")
        header["Connection"] = nil
        XCTAssertEqual(true, requiredKeepConnect(specVersion: header.firstLine.first, header: header))

        header["Connection"] = "close"
        XCTAssertEqual(header.connectionType, .close)
        XCTAssertEqual(false, requiredKeepConnect(specVersion: header.firstLine.first, header: header))

        header["Connection"] = "keep-alive"
        XCTAssertEqual(header.connectionType, .keep_alive)
        XCTAssertEqual(true, requiredKeepConnect(specVersion: header.firstLine.first, header: header))
        
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
      ("testChunkedTransfer", testChunkedTransfer),
      ("testKeepConnect", testKeepConnect),
      ("testRoute", testRoute),
    ]
}

import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket

final class swift_http_serverTests: XCTestCase {

    var calledMap = [String:Bool]()

    static let lockQueue = DispatchQueue(label: "swift_http_serverTests")
    
    /**
     example
     */
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_http_server().text, "Hello, World!")
    }

    /**
     http header test
     */
    func testHttpHeader() {
        let text = "GET / HTTP/1.1\r\nLocation: http://example.com\r\nExt: \r\n\r\n"
        let header = HttpHeader.read(text: text)
        XCTAssertEqual(header.description, text)
    }

    /**
     http header reader test
     */
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

    /**
     http server bind test
     */
    func testHttpServerBind() -> Void {
        
        let addresses = Network.getInetAddresses()

        print(" == Network.getInetAddresses() ==")
        for address in addresses {
            print("- INET Address: \(address.description)")
        }

        // -----------------------

        do {

            let server = HttpServer(port: 0)
            server.monitor(monitorName: "testHttpServerBind-1") {
                (name, status, error) in
                print(" ------------- [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
            }
            DispatchQueue.global(qos: .default).async {
                do {
                    try server.run()
                } catch let error {
                    print(error)
                }
            }
            sleep(1)
            
            print(server.serverAddress!.description)
            server.finish()

            sleep(1)

            XCTAssertFalse(server.running)
            XCTAssertEqual(server.connectedSocketCount, 0)
        }

        // -----------------------

        do {

            let hostname = Network.getInetAddress()!.hostname
            let server = HttpServer(hostname: hostname, port: 0)
            server.monitor(monitorName: "testHttpServerBind-2") {
                (name, status, error) in
                print(" ------------- [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
            }
            DispatchQueue.global(qos: .default).async {
                do {
                    try server.run()
                } catch let error {
                    print(error)
                }
            }
            sleep(1)
            guard let address = server.serverAddress else {
                XCTFail("no server.serverAddress")
                return
            }
            print(address.description)
            XCTAssertEqual(hostname, address.hostname)
            server.finish()
        }

        // -----------------------

        // do {
        //     let hostname = Network.getInetAddress()!.hostname
        //     let port = 9999
        //     let server = HttpServer(hostname: hostname, port: port)
        //     DispatchQueue.global(qos: .default).async {
        //         do {
        //             try server.run()
        //         } catch let error {
        //             print(error)
        //         }
        //     }
        //     sleep(1)
        //     guard let address = server.serverAddress else {
        //         XCTFail("no server.serverAddress")
        //         return
        //     }
        //     print(address.description)
        //     XCTAssertEqual(hostname, address.hostname)
        //     XCTAssertEqual(Int32(port), address.port)
        //     server.finish()
        // }

    }

    /**
     http server test
     */
    func testHttpServer() throws {
        
        let server = HttpServer(port: 0)
        server.monitor(monitorName: "testHttpServer-1") {
            (name, status, error) in
            print(" ------------- [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
        }

        class GetHandler: HttpRequestHandler {
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
                
            }
            
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                // response.setStatus(code: 200, reason: "GOOD") <-- deprecated but works for now
                response.status = .custom(200, "GOOD")
                response.contentType = "text/plain"
                response.data = "Hello".data(using: .utf8)
            }
        }

        class PostHandler: HttpRequestHandler {
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
                
            }
            
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                response.status = .ok
                response.contentType = request.contentType
                response.data = body
            }
        }
        
        class ErrorHandler: HttpRequestHandler {
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
                
            }
            
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                throw HttpServerError.custom(string: "!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!")
            }
        }
        
        try server.route(pattern: "/", handler: GetHandler())
        try server.route(pattern: "/post", handler: PostHandler())
        try server.route(pattern: "/error", handler: ErrorHandler())
        
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            do {
                try server.run() {
                    (server, error) in
                    guard error == nil else {
                        XCTFail("server.run() failed - \(error!)")
                        return
                    }
                    XCTAssertNotNil(server.serverAddress)
                    guard let address = server.serverAddress else {
                        XCTFail("server.serverAddress failed")
                        return
                    }
                    print("Http Server is bound to '\(address.description)'")

                    self.calledMap["notfound"] = false
                    self.calledMap["get"] = false
                    self.calledMap["post1"] = false
                    self.calledMap["post2"] = false
                    self.calledMap["post3"] = false
                    self.calledMap["post4"] = false
                    self.calledMap["post5"] = false

                    self.helperNotFound(url: URL(string: "http://localhost:\(address.port)/notfound")!,
                                        name: "notfound")

                    self.helperGet(url: URL(string: "http://localhost:\(address.port)/error")!,
                                   containsBody: "!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!",
                                   name: "error")

                    self.helperGet(url: URL(string: "http://localhost:\(address.port)")!, expectedBody: "Hello",
                                   name: "get")

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/plain", body: "HiHo".data(using: .utf8)!, expectedBody: "HiHo",
                                    name: "post1")


                    let longPacket = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
                      "<CATALOG>" +
                      "  <CD>" +
                      "    <TITLE>Empire Burlesque</TITLE>" +
                      "    <ARTIST>Bob Dylan</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>Columbia</COMPANY>" +
                      "    <PRICE>10.90</PRICE>" +
                      "    <YEAR>1985</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Hide your heart</TITLE>" +
                      "    <ARTIST>Bonnie Tyler</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>CBS Records</COMPANY>" +
                      "    <PRICE>9.90</PRICE>" +
                      "    <YEAR>1988</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Greatest Hits</TITLE>" +
                      "    <ARTIST>Dolly Parton</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>RCA</COMPANY>" +
                      "    <PRICE>9.90</PRICE>" +
                      "    <YEAR>1982</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Still got the blues</TITLE>" +
                      "    <ARTIST>Gary Moore</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Virgin records</COMPANY>" +
                      "    <PRICE>10.20</PRICE>" +
                      "    <YEAR>1990</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Eros</TITLE>" +
                      "    <ARTIST>Eros Ramazzotti</ARTIST>" +
                      "    <COUNTRY>EU</COUNTRY>" +
                      "    <COMPANY>BMG</COMPANY>" +
                      "    <PRICE>9.90</PRICE>" +
                      "    <YEAR>1997</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>One night only</TITLE>" +
                      "    <ARTIST>Bee Gees</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Polydor</COMPANY>" +
                      "    <PRICE>10.90</PRICE>" +
                      "    <YEAR>1998</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Sylvias Mother</TITLE>" +
                      "    <ARTIST>Dr.Hook</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>CBS</COMPANY>" +
                      "    <PRICE>8.10</PRICE>" +
                      "    <YEAR>1973</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Maggie May</TITLE>" +
                      "    <ARTIST>Rod Stewart</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Pickwick</COMPANY>" +
                      "    <PRICE>8.50</PRICE>" +
                      "    <YEAR>1990</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Romanza</TITLE>" +
                      "    <ARTIST>Andrea Bocelli</ARTIST>" +
                      "    <COUNTRY>EU</COUNTRY>" +
                      "    <COMPANY>Polydor</COMPANY>" +
                      "    <PRICE>10.80</PRICE>" +
                      "    <YEAR>1996</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>When a man loves a woman</TITLE>" +
                      "    <ARTIST>Percy Sledge</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>Atlantic</COMPANY>" +
                      "    <PRICE>8.70</PRICE>" +
                      "    <YEAR>1987</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Black angel</TITLE>" +
                      "    <ARTIST>Savage Rose</ARTIST>" +
                      "    <COUNTRY>EU</COUNTRY>" +
                      "    <COMPANY>Mega</COMPANY>" +
                      "    <PRICE>10.90</PRICE>" +
                      "    <YEAR>1995</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>1999 Grammy Nominees</TITLE>" +
                      "    <ARTIST>Many</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>Grammy</COMPANY>" +
                      "    <PRICE>10.20</PRICE>" +
                      "    <YEAR>1999</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>For the good times</TITLE>" +
                      "    <ARTIST>Kenny Rogers</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Mucik Master</COMPANY>" +
                      "    <PRICE>8.70</PRICE>" +
                      "    <YEAR>1995</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Big Willie style</TITLE>" +
                      "    <ARTIST>Will Smith</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>Columbia</COMPANY>" +
                      "    <PRICE>9.90</PRICE>" +
                      "    <YEAR>1997</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Tupelo Honey</TITLE>" +
                      "    <ARTIST>Van Morrison</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Polydor</COMPANY>" +
                      "    <PRICE>8.20</PRICE>" +
                      "    <YEAR>1971</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Soulsville</TITLE>" +
                      "    <ARTIST>Jorn Hoel</ARTIST>" +
                      "    <COUNTRY>Norway</COUNTRY>" +
                      "    <COMPANY>WEA</COMPANY>" +
                      "    <PRICE>7.90</PRICE>" +
                      "    <YEAR>1996</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>The very best of</TITLE>" +
                      "    <ARTIST>Cat Stevens</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Island</COMPANY>" +
                      "    <PRICE>8.90</PRICE>" +
                      "    <YEAR>1990</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Stop</TITLE>" +
                      "    <ARTIST>Sam Brown</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>A and M</COMPANY>" +
                      "    <PRICE>8.90</PRICE>" +
                      "    <YEAR>1988</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Bridge of Spies</TITLE>" +
                      "    <ARTIST>T'Pau</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Siren</COMPANY>" +
                      "    <PRICE>7.90</PRICE>" +
                      "    <YEAR>1987</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Private Dancer</TITLE>" +
                      "    <ARTIST>Tina Turner</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>Capitol</COMPANY>" +
                      "    <PRICE>8.90</PRICE>" +
                      "    <YEAR>1983</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Midt om natten</TITLE>" +
                      "    <ARTIST>Kim Larsen</ARTIST>" +
                      "    <COUNTRY>EU</COUNTRY>" +
                      "    <COMPANY>Medley</COMPANY>" +
                      "    <PRICE>7.80</PRICE>" +
                      "    <YEAR>1983</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Pavarotti Gala Concert</TITLE>" +
                      "    <ARTIST>Luciano Pavarotti</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>DECCA</COMPANY>" +
                      "    <PRICE>9.90</PRICE>" +
                      "    <YEAR>1991</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>The dock of the bay</TITLE>" +
                      "    <ARTIST>Otis Redding</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>Stax Records</COMPANY>" +
                      "    <PRICE>7.90</PRICE>" +
                      "    <YEAR>1968</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Picture book</TITLE>" +
                      "    <ARTIST>Simply Red</ARTIST>" +
                      "    <COUNTRY>EU</COUNTRY>" +
                      "    <COMPANY>Elektra</COMPANY>" +
                      "    <PRICE>7.20</PRICE>" +
                      "    <YEAR>1985</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Red</TITLE>" +
                      "    <ARTIST>The Communards</ARTIST>" +
                      "    <COUNTRY>UK</COUNTRY>" +
                      "    <COMPANY>London</COMPANY>" +
                      "    <PRICE>7.80</PRICE>" +
                      "    <YEAR>1987</YEAR>" +
                      "  </CD>" +
                      "  <CD>" +
                      "    <TITLE>Unchain my heart</TITLE>" +
                      "    <ARTIST>Joe Cocker</ARTIST>" +
                      "    <COUNTRY>USA</COUNTRY>" +
                      "    <COMPANY>EMI</COMPANY>" +
                      "    <PRICE>8.20</PRICE>" +
                      "    <YEAR>1987</YEAR>" +
                      "  </CD>" +
                      "</CATALOG>"

                    XCTAssertTrue(longPacket.count > 4096)
                    
                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml", body: longPacket.data(using: .utf8)!, expectedBody: longPacket,
                                    name: "post2")

                    let veryLongPacket = longPacket + longPacket + longPacket + longPacket + longPacket + longPacket + longPacket + longPacket + longPacket + longPacket + longPacket

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml", body: veryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryLongPacket,
                                    name: "post3")

                    let veryveryLongPacket = veryLongPacket + veryLongPacket + veryLongPacket + veryLongPacket + veryLongPacket + veryLongPacket + veryLongPacket + veryLongPacket

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml", body: veryveryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryveryLongPacket,
                                    name: "post4")

                    var veryveryveryLongPacket = veryveryLongPacket
                    for _ in 0..<100 {
                        veryveryveryLongPacket.append(veryveryLongPacket)
                    }

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml",
                                    body: veryveryveryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryveryveryLongPacket,
                                    name: "post5")
                }
            } catch let error {
                XCTFail("error occured - \(error)")
            }
        }

        sleep(6)

        server.finish()

        sleep(1)

        XCTAssertFalse(server.running)
        XCTAssertEqual(server.connectedSocketCount, 0)

        for (k, v) in calledMap {
            print(k)
            XCTAssertTrue(v)
        }
    }

    func helperNotFound(url: URL, name: String) {
        let req = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperGet() - error: \(error!)")
                return
            }

            guard let urlresponse = response as? HTTPURLResponse else {
                XCTFail("not http url response")
                return
            }

            XCTAssertEqual(urlresponse.statusCode, 404)

            swift_http_serverTests.lockQueue.sync {
                [self] in
                calledMap[name] = true
            }
        }
        task.resume()
    }

    func helperGet(url: URL, expectedBody: String, name: String) {
        let req = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperGet() - error: \(error!)")
                return
            }
            guard let _data = data else {
                print("error: no response data")
                return
            }
            guard let body = String(data: _data, encoding: .utf8) else {
                XCTFail("String(data: _data, encoding: .utf8) failed")
                return
            }
            XCTAssertEqual(expectedBody, body)

            swift_http_serverTests.lockQueue.sync {
                [self] in
                calledMap[name] = true
            }
        }
        task.resume()
    }

    func helperGet(url: URL, containsBody: String, name: String) {
        let req = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperGet() - error: \(error!)")
                return
            }
            guard let _data = data else {
                print("error: no response data")
                return
            }
            guard let body = String(data: _data, encoding: .utf8) else {
                XCTFail("String(data: _data, encoding: .utf8) failed")
                return
            }
            XCTAssertTrue(body.contains(containsBody))

            swift_http_serverTests.lockQueue.sync {
                [self] in
                calledMap[name] = true
            }
        }
        task.resume()
    }

    func helperPost(url: URL, contentType: String, body: Data, expectedBody: String, name: String) {
        print("POST Data size: \(body.count)")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperPost() - error: \(error!)")
                return
            }
            guard let _data = data else {
                print("error: no response data")
                return
            }
            guard let body = String(data: _data, encoding: .utf8) else {
                XCTFail("String(data: _data, encoding: .utf8) failed")
                return
            }
            XCTAssertEqual(expectedBody, body)

            swift_http_serverTests.lockQueue.sync {
                [self] in 
                calledMap[name] = true
            }
        }
        task.resume()
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

    static var allTests = [
      ("testExample", testExample),
      ("testHttpHeader", testHttpHeader),
      ("testHttpHeaderReader", testHttpHeaderReader),
      ("testHttpServer", testHttpServer),
      ("testHttpServerBind", testHttpServerBind),
      ("testChunkedTransfer", testChunkedTransfer),
      ("testKeepConnect", testKeepConnect),
    ]
}

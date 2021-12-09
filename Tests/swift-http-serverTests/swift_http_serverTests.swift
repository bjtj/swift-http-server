import XCTest
@testable import SwiftHttpServer

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket

final class swift_http_serverTests: XCTestCase {

    var calledMap = [String:Int]()
    static let lockQueue = DispatchQueue(label: "swift_http_serverTests")
    static let closeConnection = false
    static let enabledTestChunked = false

    // TEST -- http server bind test
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

        // -----------------------------
        // Specific Hostname & Port Bind

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

    // TEST -- http server test
    func testHttpServer() throws {
        
        let server = HttpServer(port: 0)
        server.monitor(monitorName: "testHttpServer-1") {
            (name, status, error) in
            print(" ------------- [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
        }
        server.connectionFilter = {
            (socket) in

            guard let signature = socket.signature else {
                XCTFail("wierd socket! not signature")
                return false
            }

            guard let hostname = signature.hostname else {
                XCTFail("wierd socket! no hostname")
                return false
            }
            
            print("connected -- (\(hostname):\(signature.port))")
            return true
        }

        // `Get` handler
        class GetHandler: HttpRequestHandler {
            var dumpBody: Bool = true

            func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
                
            }
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                // response.setStatus(code: 200, reason: "GOOD") <-- deprecated but works for now
                response.status = .custom(200, "GOOD")
                response.contentType = "text/plain"
                response.data = "Hello".data(using: .utf8)
            }
        }

        // `Post` Handler
        class PostHandler: HttpRequestHandler {
            
            var dumpBody: Bool = true
            
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
                
            }
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                response.status = .ok
                response.contentType = request.contentType
                response.data = body
            }
        }

        // `Error` Handler
        class ErrorHandler: HttpRequestHandler {
            
            var dumpBody: Bool = true
            
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
            }
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                throw HttpServerError.custom(string: "!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!")
            }
        }

        // `Chunked Transfer` Handler
        class ChunkedHandler: HttpRequestHandler {
            
            var dumpBody: Bool = true
            
            func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
                guard request.header.transferEncoding == .chunked else {
                    throw HttpServerError.custom(string: "NOT CHUNKED TRANSFER !!")
                }
                request.body = Data()
            }

            func onBodyData(data: Data?, request: HttpRequest, response: HttpResponse) throws {
                guard let data = data else {
                    throw HttpServerError.custom(string: "NO DATA ON BODY DATA !!")
                }

                guard let string = String(data: data, encoding: .utf8) else {
                    XCTFail("Failed data string")
                    return
                }
                print("DATA -- '\(string)'")
            }
            
            func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
                response.status = .ok
                response.contentType = "plain/text"
                response.data = body
            }
        }
        
        try server.route(pattern: "/", handler: GetHandler())
        try server.route(pattern: "/post", handler: PostHandler())
        try server.route(pattern: "/error", handler: ErrorHandler())
        try server.route(pattern: "/chunked", handler: ChunkedHandler())
        
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

                    self.calledMap["notfound"] = 0
                    self.calledMap["get"] = 0
                    self.calledMap["error"] = 0
                    self.calledMap["post1"] = 0
                    self.calledMap["post2"] = 0
                    self.calledMap["post3"] = 0
                    self.calledMap["post4"] = 0
                    self.calledMap["post5"] = 0
                    if swift_http_serverTests.enabledTestChunked {
                        self.calledMap["chunked"] = 0
                    }

                    print("self.calledMap.count --- \(self.calledMap.count)")

                    // -*- not found -*-

                    self.helperNotFound(url: URL(string: "http://localhost:\(address.port)/notfound")!,
                                        name: "notfound")

                    // -*- get -*-

                    self.helperGet(url: URL(string: "http://localhost:\(address.port)/error")!,
                                   containsBody: "!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!",
                                   name: "error")

                    // -*- get -*-

                    self.helperGet(url: URL(string: "http://localhost:\(address.port)")!,
                                   expectedBody: "Hello",
                                   name: "get")

                    // -*- post -*-

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/plain",
                                    body: "HiHo".data(using: .utf8)!,
                                    expectedBody: "HiHo",
                                    name: "post1")

                    // -*- post long -*-

                    let longPacket = self.xmlSamplePacket

                    XCTAssertTrue(longPacket.count > 4096)
                    
                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml",
                                    body: longPacket.data(using: .utf8)!,
                                    expectedBody: longPacket,
                                    name: "post2")

                    // -*- post very long -*-
                    
                    let veryLongPacket = self.utilMultiplyString(string: longPacket, count: 11)

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml",
                                    body: veryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryLongPacket,
                                    name: "post3")

                    // -*- post very very long -*-
                    
                    let veryveryLongPacket = self.utilMultiplyString(string: veryLongPacket, count: 8)

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml",
                                    body: veryveryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryveryLongPacket,
                                    name: "post4")

                    // -*- post very very very long -*-
                    
                    let veryveryveryLongPacket = self.utilMultiplyString(string: veryveryLongPacket, count: 101)

                    XCTAssertEqual(veryveryveryLongPacket.count, 41373640)

                    self.helperPost(url: URL(string: "http://localhost:\(address.port)/post")!,
                                    contentType: "text/xml",
                                    body: veryveryveryLongPacket.data(using: .utf8)!,
                                    expectedBody: veryveryveryLongPacket,
                                    name: "post5")

                    // -*- chunked -*-

                    if swift_http_serverTests.enabledTestChunked {
                        self.helperChunked(url: URL(string: "http://localhost:\(address.port)/chunked")!,
                                           dataArray: ["hello1".data(using: .utf8)!,
                                                       "hello12".data(using: .utf8)!,
                                                       "hello123".data(using: .utf8)!,
                                                       "hello1234".data(using: .utf8)!,
                                                       "hello12345".data(using: .utf8)!,
                                                       "hello123456".data(using: .utf8)!,
                                                       "hello1234567".data(using: .utf8)!,
                                                       "hello12345678".data(using: .utf8)!,
                                                       "hello123456789".data(using: .utf8)!,
                                                       "hello1234567890".data(using: .utf8)!,
                                                       "hello12345678901".data(using: .utf8)!,
                                                       "hello123456789012".data(using: .utf8)!,
                                                       "hello1234567890123".data(using: .utf8)!,
                                                       "hello12345678901234".data(using: .utf8)!,
                                                       "hello123456789012345".data(using: .utf8)!,],
                                           name: "chunked")
                    }

                    
                }
            } catch let error {
                XCTFail("error occured - \(error)")
            }
        }

        sleep(10)

        server.finish()

        sleep(1)

        XCTAssertFalse(server.running)
        XCTAssertEqual(server.connectedSocketCount, 0)

        for (k, v) in calledMap {
            print("\(k) called? \(v > 0) (\(v))")
            XCTAssertTrue(v > 0)
        }
    }

    // UTIL -- Multiply String
    func utilMultiplyString(string: String, count: Int) -> String {
        var ret = ""
        for _ in 0..<count {
            ret += string
        }
        return ret
    }

    // HELPER -- NOT FOUND
    func helperNotFound(url: URL, name: String) {
        var req = URLRequest(url: url)
        req.addValue(name, forHTTPHeaderField: "x-name")
        req.addValue("close", forHTTPHeaderField: "Connection")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperNotFound() - error: \(error!)")
                return
            }

            guard let urlresponse = response as? HTTPURLResponse else {
                XCTFail("not http url response")
                return
            }

            XCTAssertEqual(urlresponse.statusCode, 404)

            swift_http_serverTests.lockQueue.sync {
                [self] in
                self.calledMap[name] = self.calledMap[name]! + 1
            }
        }
        task.resume()
    }

    // HELPER -- GET
    func helperGet(url: URL, expectedBody: String, name: String) {
        var req = URLRequest(url: url)
        req.addValue(name, forHTTPHeaderField: "x-name")
        req.addValue("close", forHTTPHeaderField: "Connection")
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
                self.calledMap[name] = self.calledMap[name]! + 1
            }
        }
        task.resume()
    }

    // HELPER -- GET
    func helperGet(url: URL, containsBody: String, name: String) {
        var req = URLRequest(url: url)
        req.addValue(name, forHTTPHeaderField: "x-name")
        req.addValue("close", forHTTPHeaderField: "Connection")
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
                self.calledMap[name] = self.calledMap[name]! + 1
            }
        }
        task.resume()
    }

    // HELPER -- POST
    func helperPost(url: URL, contentType: String, body: Data, expectedBody: String, name: String) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        req.addValue(name, forHTTPHeaderField: "x-name")
        req.addValue("close", forHTTPHeaderField: "Connection")
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
            guard expectedBody.count == body.count else {
                XCTFail("failed (expectedBody.count \(expectedBody.count) == body.count \(body.count))")
                return
            }
            XCTAssertEqual(expectedBody, body)

            swift_http_serverTests.lockQueue.sync {
                [self] in 
                self.calledMap[name] = self.calledMap[name]! + 1
            }
        }
        task.resume()
    }


    // HELPER -- CHUNKED TRANSFER
    func helperChunked(url: URL, dataArray: [Data], name: String) {
        // TODO:

        // https://developer.apple.com/documentation/foundation/inputstream
        class MyInputStream : InputStream {

            var idx = 0
            var dataArray: [Data]

            override var hasBytesAvailable: Bool {
                return idx < dataArray.count
            }

            init(dataArray: [Data]) {
                self.dataArray = dataArray
                super.init(data: Data(capacity: 4096))
            }

            override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
                guard idx < dataArray.count else {
                    return 0
                }
                let data = dataArray[idx]
                let count = min(data.count, len)
                data.copyBytes(to: buffer, count: count)
                idx += 1

                // usleep(500 * 1000)
                
                return count
            }

            override func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
                return false
            }
        }

        let len = dataArray.reduce(0, { $0 + $1.count })

        let session = URLSession(configuration: URLSessionConfiguration.default)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBodyStream = MyInputStream(dataArray: dataArray)
        req.addValue(name, forHTTPHeaderField: "x-name")
        req.addValue("close", forHTTPHeaderField: "Connection")
        req.addValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        // req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        let task = session.dataTask(with: req) {
            (data, response, error) in
            guard error == nil else {
                print("helperChunked() - error: \(error!)")
                return
            }
            guard let data = data else {
                print("error: no response data")
                return
            }
            guard let body = String(data: data, encoding: .utf8) else {
                XCTFail("String(data: _data, encoding: .utf8) failed")
                return
            }

            XCTAssertEqual(len, body.count)
            print(body)

            swift_http_serverTests.lockQueue.sync {
                [self] in 
                self.calledMap[name] = self.calledMap[name]! + 1
            }
        }
        task.resume()
    }

    // TEST chunked tranfser
    func testChunkedTransfer() throws {
        // fixed size
        // chunked

        let data = "5\r\nhello\r\n6\r\n world\r\n0\r\n\r\n".data(using: .utf8)
        guard let transfer = try ChunkedTransfer(remoteSocket: try Socket.create(), startWithData: data) else {
            XCTFail("failed initialize chunked tranfser")
            return
        }

        XCTAssertEqual(try transfer.readSize(), 5)
        XCTAssertEqual(try transfer.readContent(size: 5), "hello".data(using: .utf8))
        XCTAssertEqual(try transfer.readSize(), 6)
        XCTAssertEqual(try transfer.readContent(size: 6), " world".data(using: .utf8))
        XCTAssertEqual(try transfer.readSize(), 0)
        XCTAssertNil(try transfer.readContent(size: 0))
    }

    static var allTests = [
      ("testHttpServer", testHttpServer),
      ("testHttpServerBind", testHttpServerBind),
      ("testChunkedTransfer", testChunkedTransfer),
    ]

    let xmlSamplePacket = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
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
}

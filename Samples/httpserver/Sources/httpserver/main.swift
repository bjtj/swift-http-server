import SwiftHttpServer
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket


func main() throws {

    var bindHostname:String? = nil
    var bindPort:Int = 9999
    if CommandLine.arguments.count == 3 {
        bindHostname = CommandLine.arguments[1]
        guard let port = Int(CommandLine.arguments[2]) else {
            print("Error - not port number format '\(CommandLine.arguments[2])'")
            return
        }
        bindPort = port
    } else if CommandLine.arguments.count == 2 {
        guard let port = Int(CommandLine.arguments[1]) else {
            print("Error - not port number format '\(CommandLine.arguments[1])'")
            return
        }
        bindPort = port
    }
    
    let server = HttpServer(hostname: bindHostname, port: bindPort)

    server.monitor(monitorName: "sample-http-server") {
        (name, status, error) in
        print(" [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
    }

    server.connectionFilter = {
        (socket) in
        guard let signature = socket.signature else {
            print("NO SIGNATURE!")
            return false
        }
        guard let hostname = signature.hostname else {
            print("NO HOSTNAME")
            return false
        }
        print("[CONNECTED] remote socket -- '\(hostname):\(signature.port)'")
        return true
    }

    class GetHandler: HttpRequestHandler {
        
        var dumpBody: Bool = true
        
        func onHeaderCompleted(header: HttpHeader, request: HttpRequest,  response: HttpResponse) throws {
            
        }
        
        func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
            // response.setStatus(code: 200, reason: "GOOD") <-- deprecated but works for now
            response.status = .custom(200, "GOOD")
            response.contentType = "text/plain"
            response.data = "Hello\n".data(using: .utf8)
        }
    }

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
    
    class ErrorHandler: HttpRequestHandler {

        var dumpBody: Bool = true
        
        func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
        }
        
        func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
            throw HttpServerError.custom(string: "!!!!!!!!!!!!!!!!!ERROR!!!!!!!!!!!!!!!!!!!")
        }
    }

    class ChunkedHandler: HttpRequestHandler {

        var dumpBody: Bool = true
        
        func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws {
            guard header.transferEncoding == .chunked else {
                throw HttpServerError.custom(string: "not chunked transfer")
            }
        }

        func onBodyData(data: Data?, request: HttpRequest, response: HttpResponse) throws {
            guard let _ = data else {
                throw HttpServerError.custom(string: "no data")
            }
        }
        
        func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws {
            response.status = .ok
            response.contentType = request.contentType
            response.data = body
        }
    }
    
    try server.route(pattern: "/", handler: GetHandler())
    try server.route(pattern: "/post", handler: PostHandler())
    try server.route(pattern: "/error", handler: ErrorHandler())
    try server.route(pattern: "/chunked", handler: ChunkedHandler())

    DispatchQueue.global(qos: .default).async {
        do {
            try server.run() {
                (server, error) in
                guard error == nil else {
                    print("http server error!")
                    return
                }
                guard let address = server.serverAddress else {
                    print("server.serverAddress failed")
                    return
                }
                print("Http Server is bound to '\(address.description)'")
            }
        } catch let error {
            print(error)
        }
    }

    var done = false

    while done == false {
        guard let line = readLine() else {
            continue
        }
        switch line {
        case "quit", "q":
            done = true
            break
        default:
            break
        }
    }
    print("BYE")
}


try main()


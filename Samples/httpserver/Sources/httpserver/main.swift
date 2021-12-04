import SwiftHttpServer
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Socket


func main() throws {
    let server = HttpServer(port: 9999)

    server.monitor(monitorName: "sample-http-server") {
        (name, status, error) in
        print(" [\(name ?? "nil")] HTTP SERVER Status changed to '\(status)'")
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


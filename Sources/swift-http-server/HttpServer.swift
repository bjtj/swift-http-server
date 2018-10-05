import Foundation
import Socket

public enum HttpHeaderError : Error {
    case insufficentHeaderString
}

public class HttpServer {

    var finishing = false
    var listenSocket: Socket?
    var port: Int
    var backlog: Int
    var reusePort: Bool
    var connectedSockets = [Int32: Socket]()
    let router = Router()

    public init(port: Int = 0, backlog: Int = 5, reusePort: Bool = true) {
        self.port = port
        self.backlog = backlog
        self.reusePort = reusePort
    }

    public var serverAddress: InetAddress? {
        guard let hostname = listenSocket?.signature!.hostname,
              let port = listenSocket?.signature!.port else {
            return nil
        }
        if listenSocket?.signature!.protocolFamily == .inet {
            return InetAddress(version: .ipv4, hostname: hostname, port: port)
        }
        if listenSocket?.signature!.protocolFamily == .inet6 {
            return InetAddress(version: .ipv6, hostname: hostname, port: port)
        }
        return nil
    }

    public var listeningPort: Int32 {
        return listenSocket!.listeningPort
    }

    public func route(pattern: String, handler: HttpRequestHandler?) throws {
        if handler == nil {
            try router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    public func route(pattern: String, handler: HttpRequestClosure?) throws {
        if handler == nil {
            try router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    func communicate(remoteSocket: Socket) {

        do {
            let headerString = try readHeaderString(remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)
            guard let response = handleRequest(request: request) else {
                let response = errorResponse(code: 500)
                try sendResponse(socket: remoteSocket, response: response)
                return
            }
            try sendResponse(socket: remoteSocket, response: response)
        } catch let error {
            print("error: \(error)")
        }
    }

    func sendResponse(socket: Socket, response: HttpResponse) throws {
        try socket.write(from: response.header.description.data(using: .utf8)!)
        if let data = response.data {
            if response.header.transferEncoding == .chunked {
                try socket.write(from: "\(data.count)\r\n".data(using: .utf8)!)
            }
            try socket.write(from: data)
        }
        if let stream = response.stream {
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if response.header.transferEncoding == .chunked {
                    try socket.write(from: "\(read)\r\n".data(using: .utf8)!)
                }
                try socket.write(from: buffer, bufSize: read)
            }
            buffer.deallocate()
        }
    }

    func errorResponse(code: Int) -> HttpResponse {
        let reason = HttpStatusCode.shared[code]
        let response = HttpResponse(code: code, reason: reason!)
        response.header.contentType = "text/plain"
        response.data = "\(code) \(reason!)".data(using: .utf8)
        return response
    }

    func readHeaderString(remoteSocket: Socket?) throws -> String {
        var data = Data(capacity: 1)
        var headerString = ""
        while self.finishing == false {
            if try remoteSocket?.isReadableOrWritable(timeout: 1_000).0 == false {
                continue
            }

            let bytesRead = try remoteSocket?.read(into: &data)
            if bytesRead! <= 0 {
                throw HttpHeaderError.insufficentHeaderString
            }
            headerString += String(data: data, encoding: .utf8)!
            if headerString.hasSuffix("\r\n\r\n") {
                break
            }
        }
        return headerString
    }

    func handleRequest(request: HttpRequest) -> HttpResponse? {
        do {
            guard let handler = router.dispatch(path: request.path) else {
                return HttpResponse(code: 400, reason: HttpStatusCode.shared[404])
            }
            return try handler.onHttpRequest(request: request)
        } catch let error {
            print("error: \(error)")
            return HttpResponse(code: 500, reason: HttpStatusCode.shared[500])
        }
    }

    func onConnect(remoteSocket: Socket) {
        connectedSockets[remoteSocket.socketfd] = remoteSocket
        DispatchQueue.global(qos: .default).async {
            [unowned self, remoteSocket] in
            self.communicate(remoteSocket: remoteSocket)
            remoteSocket.close()
            self.onDisconnect(remoteSocket: remoteSocket)
        }
    }

    func onDisconnect(remoteSocket: Socket) {
        connectedSockets[remoteSocket.socketfd] = nil
    }

    func loop() throws {
        listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        try listenSocket?.listen(on: port, maxBacklogSize: backlog, allowPortReuse: reusePort)
        repeat {
            guard let remoteSocket = try listenSocket?.acceptClientConnection() else {
                return
            }
            onConnect(remoteSocket: remoteSocket)
        } while finishing == false
        listenSocket?.close()
        listenSocket = nil
    }

    public func run() throws {
        finishing = false
        try loop()
    }

    public func finish() {
        finishing = true
    }
}

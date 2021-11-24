import Foundation
import Socket


/**
 HttpServerDelegate
 */
public protocol HttpServerDelegate {
    func onConnect(remoteSocket: Socket)
    func onDisconnect(remoteSocket: Socket)
    func onHeaderCompleted(header: HttpHeader)
}

/**
 Http Server
 */
public class HttpServer {

    var finishing = false
    var listenSocket: Socket?
    var port: Int
    var backlog: Int
    var reusePort: Bool
    var connectedSockets = [Int32: Socket]()
    let router = Router()
    var delegate: HttpServerDelegate?

    public init(port: Int = 0, backlog: Int = 5, reusePort: Bool = true, delegate: HttpServerDelegate? = nil) {
        self.port = port
        self.backlog = backlog
        self.reusePort = reusePort
        self.delegate = delegate
    }

    /**
     Get Server Address
     */
    public var serverAddress: InetAddress? {

        guard let listenSocket = listenSocket else {
            print("HttpServer::serverAddress error - no listen socket")
            return nil
        }

        guard let signature = listenSocket.signature else {
            print("HttpServer::serverAddress error - no signature in listen socket")
            return nil
        }
        
        guard let hostname = signature.hostname else {
            print("HttpServer::serverAddress error - no hostname in signature")
            return nil
        }
        
        if signature.protocolFamily == .inet {
            return InetAddress(version: .ipv4, hostname: hostname, port: signature.port)
        }
        
        if signature.protocolFamily == .inet6 {
            return InetAddress(version: .ipv6, hostname: hostname, port: signature.port)
        }
        return nil
    }

    /**
     Get Listening Port
     */
    public var listeningPort: Int32? {
        return listenSocket?.listeningPort
    }

    /**
     Set Router
     */
    public func route(pattern: String, handler: HttpRequestHandler?) throws {
        if handler == nil {
            try router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    /**
     Set Router
     */
    public func route(pattern: String, handler: HttpRequestClosure?) throws {
        if handler == nil {
            try router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    func communicate(remoteSocket: Socket) {

        do {
            let (headerString, remainingData) = try readHeaderString(remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            delegate?.onHeaderCompleted(header:header)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)
            let (body, _) = try readBody(remainingData: remainingData,
                                         remoteSocket: remoteSocket,
                                         contentLength: header.contentLength ?? 0)
            if let body = body {
                request.body = body
            }
            guard let response = handleRequest(request: request) else {
                print("HttpServer::communicate() error - handleRequest failed")
                let response = errorResponse(code: 500)
                try sendResponse(socket: remoteSocket, response: response)
                return
            }
            try sendResponse(socket: remoteSocket, response: response)
        } catch let error {
            print("HttpServer::communicate() error: \(error)")
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

    func readHeaderString(remoteSocket: Socket?) throws -> (String, Data) {
        var readBuffer = Data()
        var buffer = Data()

        guard let remoteSocket = remoteSocket else {
            throw HttpServerError.custom(string: "no socket")
        }
        
        while self.finishing == false {
            if try remoteSocket.isReadableOrWritable(timeout: 1_000).0 == false {
                continue
            }
            let bytesRead = try remoteSocket.read(into: &readBuffer)
            if bytesRead <= 0 {
                throw HttpServerError.insufficientHeaderString
            }
            buffer.append(readBuffer)
            guard let range = buffer.range(of: "\r\n\r\n".data(using: .utf8)!) else {
                continue
            }
            let headerBuffer = buffer.subdata(in: 0..<range.lowerBound)

            let header = String(data: headerBuffer, encoding: .utf8)
            let remainingData = buffer.subdata(in: range.upperBound..<buffer.endIndex)

            return (header!, remainingData)
        }
        throw HttpServerError.custom(string: "readHeaderString() failed")
    }

    func readBody(remainingData: Data?, remoteSocket: Socket, contentLength: Int) throws -> (Data?, Data?) {
        var bodyBuffer = Data()
        var readBuffer = Data()

        guard contentLength >= 0 else {
            throw HttpServerError.custom(string: "Content Length must not be negative value but \(contentLength)")
        }

        if contentLength == 0 {
            return (nil, nil)
        }

        if let remainingData = remainingData {
            bodyBuffer.append(remainingData)
        }

        if bodyBuffer.count >= contentLength {
            return (bodyBuffer.subdata(in: 0..<contentLength),
                    bodyBuffer.subdata(in: contentLength..<bodyBuffer.endIndex))
        }

        while bodyBuffer.count < contentLength && finishing == false {
            let bytesRead = try remoteSocket.read(into: &readBuffer)

            guard readBuffer.count == bytesRead else {
                throw HttpServerError.custom(string: "HttpServer::readBody() error - insufficient read bytes \(bytesRead)")
            }

            bodyBuffer.append(readBuffer)
            
            if bodyBuffer.count >= contentLength {
                return (bodyBuffer.subdata(in: 0..<contentLength),
                        bodyBuffer.subdata(in: contentLength..<bodyBuffer.endIndex))
            }
        }
        throw HttpServerError.custom(string: "HttpServer::readBody() failed")
    }

    func handleRequest(request: HttpRequest) -> HttpResponse? {
        do {
            guard let handler = router.dispatch(path: request.path) else {
                print("response 404!")
                return HttpResponse(code: 404, reason: HttpStatusCode.shared[404])
            }
            return try handler.onHttpRequest(request: request)
        } catch let error {
            print("HttpServer::handleRequest() error: \(error)")
            return HttpResponse(code: 500, reason: HttpStatusCode.shared[500])
        }
    }

    func onConnect(remoteSocket: Socket) {
        connectedSockets[remoteSocket.socketfd] = remoteSocket
        delegate?.onConnect(remoteSocket: remoteSocket)
        DispatchQueue.global(qos: .default).async {
            [unowned self, remoteSocket] in
            self.communicate(remoteSocket: remoteSocket)
            remoteSocket.close()
            self.onDisconnect(remoteSocket: remoteSocket)
        }
    }

    func onDisconnect(remoteSocket: Socket) {
        delegate?.onDisconnect(remoteSocket: remoteSocket)
        connectedSockets[remoteSocket.socketfd] = nil
        // TODO: remove socket from array
    }

    func loop() throws {
        guard let listenSocket = listenSocket else {
            print("HttpServer::loop() error - no listen socket")
            return
        }
        
        try listenSocket.listen(on: port, maxBacklogSize: backlog, allowPortReuse: reusePort)
        repeat {
            let remoteSocket = try listenSocket.acceptClientConnection()
            onConnect(remoteSocket: remoteSocket)
        } while finishing == false
        listenSocket.close()
    }

    public func run() throws {
        finishing = false

        listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        
        try loop()

        listenSocket = nil
    }

    public func finish() {
        finishing = true
    }
}

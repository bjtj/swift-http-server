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
    let router = HttpServerRouter()
    var delegate: HttpServerDelegate?
    let block = DispatchSemaphore(value: 1)

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
    public func route(pattern: String, handler: HttpRequestHandlerDelegate?) throws {
        if handler == nil {
            router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    func communicate(remoteSocket: Socket) {

        readSend(remoteSocket: remoteSocket, startWithData: nil)
    }

    func readSend(remoteSocket: Socket, startWithData: Data?) {
        do {
            let (headerString, remainingData) = try readHeaderString(startWithData: startWithData, remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            delegate?.onHeaderCompleted(header:header)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)

            guard let handler = router.dispatch(path: request.path) else {
                try sendResponse(socket: remoteSocket, response: errorResponse(code: 404))
                return
            }

            let response = HttpResponse(code: 404)
            
            do {
                try handler.onHeaderCompleted(header: header, request: request, response: response)
            } catch let err {
                try sendResponse(socket: remoteSocket, response: errorResponse(code: 500, customBody: "Operation Failed - with: \(err)"))
            }
            
            let (body, _) = try readBody(startWithData: remainingData,
                                         remoteSocket: remoteSocket,
                                         contentLength: header.contentLength ?? 0)
            request.body = body

            do {
                try handler.onBodyCompleted(body: body, request: request, response: response)
            } catch let err {
                try sendResponse(socket: remoteSocket, response: errorResponse(code: 500, customBody: "Operation Failed - with: \(err)"))
            }
            
            try sendResponse(socket: remoteSocket, response: response)
        } catch let error {
            print("HttpServer::readSend() error: \(error)")
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

    func errorResponse(code: Int, customBody: String? = nil) -> HttpResponse {
        let reason = HttpStatusCode.shared[code] ?? "Unknown"
        let response = HttpResponse(code: code, reason: reason)
        response.header.contentType = "text/plain"
        if let body = customBody {
            response.data = body.data(using: .utf8)
        } else {
            response.data = "Error: \(code) \(reason)".data(using: .utf8)
        }
        return response
    }

    func readHeaderString(startWithData: Data?, remoteSocket: Socket?) throws -> (String, Data?) {
        var readBuffer = Data()
        var buffer = Data()

        guard let remoteSocket = remoteSocket else {
            throw HttpServerError.custom(string: "HttpServer::readHeaderString() error - No Socket")
        }

        if let startWithData = startWithData {
            buffer.append(startWithData)
        }

        if let range = buffer.range(of: "\r\n\r\n".data(using: .utf8)!) {
            let (headerData, remainingData) = splitDataWithRange(data: buffer, range: range)

            guard let header = headerData else {
                throw HttpServerError.custom(string: "split data failed")
            }
            
            return (String(data: header, encoding: .utf8)!, remainingData)
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
            
            let (headerData, remainingData) = splitDataWithRange(data: buffer, range: range)

            guard let header = headerData else {
                throw HttpServerError.custom(string: "split data failed")
            }

            return (String(data: header, encoding: .utf8)!, remainingData)
        }
        
        throw HttpServerError.custom(string: "HttpServer::readHeaderString() failed")
    }

    func splitDataWithRange(data: Data, range: Range<Data.Index>) -> (Data?, Data?) {
        let a = data.subdata(in: 0..<range.lowerBound)
        let b = data.subdata(in: range.upperBound..<data.endIndex)
        return (a, b)
    }
    
    func readBody(startWithData: Data?, remoteSocket: Socket, contentLength: Int) throws -> (Data?, Data?) {
        var bodyBuffer = Data()
        var readBuffer = Data()

        guard contentLength >= 0 else {
            throw HttpServerError.custom(string: "Content Length must not be negative value but \(contentLength)")
        }

        if contentLength == 0 {
            return (nil, nil)
        }

        if let startWithData = startWithData {
            bodyBuffer.append(startWithData)
        }

        if bodyBuffer.count >= contentLength {
            return splitDataWithPostion(data: bodyBuffer, position: contentLength)
        }

        while bodyBuffer.count < contentLength && finishing == false {
            let bytesRead = try remoteSocket.read(into: &readBuffer)

            guard readBuffer.count == bytesRead else {
                throw HttpServerError.custom(string: "HttpServer::readBody() error - insufficient read bytes \(bytesRead)")
            }

            bodyBuffer.append(readBuffer)
            
            if bodyBuffer.count >= contentLength {
                return splitDataWithPostion(data: bodyBuffer, position: contentLength)
            }
        }
        throw HttpServerError.custom(string: "HttpServer::readBody() failed")
    }

    func splitDataWithPostion(data: Data, position: Int) -> (Data?, Data?) {
        let a = data.subdata(in: 0..<position)
        let b = data.subdata(in: position..<data.endIndex)
        return (a, b)
    }

    func onConnect(remoteSocket: Socket) {
        self.block.wait()
        connectedSockets[remoteSocket.socketfd] = remoteSocket
        self.block.signal()
        
        delegate?.onConnect(remoteSocket: remoteSocket)
        DispatchQueue.global(qos: .default).async {
            [unowned self, remoteSocket] in
            self.communicate(remoteSocket: remoteSocket)

            self.block.wait()
            self.delegate?.onDisconnect(remoteSocket: remoteSocket)
            self.connectedSockets[remoteSocket.socketfd] = nil
            self.block.signal()

            remoteSocket.close()
        }
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

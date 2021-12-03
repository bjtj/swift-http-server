import Foundation
import Socket



/**
 Http Server
 */
public class HttpServer {

    public enum Status {
        case idle
        case started
        case stopped
    }

    public typealias monitorHandlerType = ((String?, HttpServer.Status, Error?) -> Void)

    var status: Status = .idle

    var monitorName: String?
    var finishing = false
    var _running = false
    public var running: Bool {
        get {
            return _running
        }
    }
    var listenSocket: Socket?
    var hostname: String?
    var port: Int
    var backlog: Int
    var reusePort: Bool
    var connectedSockets = [Int32: Socket]()
    public var connectedSocketCount: Int {
        get {
            return connectedSockets.count
        }
    }
    let router = HttpServerRouter()
    let lockQueue = DispatchQueue(label: "com.tjapp.swiftHttpServer.lockQueue")
    var bufferSize = 4096
    var monitorHandler: monitorHandlerType?

    public init(hostname: String? = nil, port: Int = 0, backlog: Int = 5, reusePort: Bool = true) {
        self.hostname = hostname
        self.port = port
        self.backlog = backlog
        self.reusePort = reusePort
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
            router.unregister(pattern: pattern)
        } else {
            try router.register(pattern: pattern, handler: handler);
        }
    }

    /**
     set monitor
     */
    public func monitor(monitorName: String?, monitorHandler: monitorHandlerType?) -> Void {
        self.monitorName = monitorName
        self.monitorHandler = monitorHandler
    }

    /**
     run
     */
    public func run(readyHandler: ((HttpServer, Error?) -> Void)? = nil) throws {

        if _running {
            throw HttpServerError.alreadyRunning
        }
        
        finishing = false
        _running = true
        status = .started
        monitorHandler?(monitorName, status, nil)

        defer {
            listenSocket = nil
            _running = false
            status = .stopped
            monitorHandler?(monitorName, status, nil)
        }
        
        listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        try prepare()
        readyHandler?(self, nil)
        loop()
    }

    func prepare() throws {
        guard let listenSocket = listenSocket else {
            throw HttpServerError.custom(string: "HttpServer::prepare() error - no listen socket")
        }
        try listenSocket.listen(on: port, maxBacklogSize: backlog, allowPortReuse: reusePort, node: hostname)
    }

    func loop() {
        guard let listenSocket = listenSocket else {
            print("HttpServer::loop() error - no listen socket")
            return
        }
        repeat {
            do {
                let remoteSocket = try listenSocket.acceptClientConnection()
                onConnect(remoteSocket: remoteSocket)
            } catch let error {
                guard let socketError = error as? Socket.Error else {
		            print("HttpServer::loop() - Unexpected error...\n \(error)")
		            break
		        }
		        if !self.finishing {
		            print("HttpServer::loop() error reported:\n \(socketError.description)")
                }
                break
            }
        } while finishing == false
        listenSocket.close()
    }

    func onConnect(remoteSocket: Socket) {

        lockQueue.sync { [unowned self, remoteSocket] in
            connectedSockets[remoteSocket.socketfd] = remoteSocket
        }
        
        DispatchQueue.global(qos: .default).async {
            [unowned self, remoteSocket] in
            self.communicate(remoteSocket: remoteSocket)

            self.lockQueue.sync { [unowned self, remoteSocket] in
                self.connectedSockets[remoteSocket.socketfd] = nil
            }
            remoteSocket.close()
        }
    }

    func communicate(remoteSocket: Socket) {

        readSend(remoteSocket: remoteSocket, startWithData: nil)
    }

    func readSend(remoteSocket: Socket, startWithData: Data?) {
        do {
            let (headerString, remainingData) = try readHeaderString(startWithData: startWithData,
                                                                     remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)

            guard let handler = router.dispatch(path: request.path) else {
                try sendResponse(socket: remoteSocket, response: errorResponse(code: 404))
                return
            }

            let response = HttpResponse(code: 404)
            
            do {
                try handler.onHeaderCompleted(header: header, request: request, response: response)

                
                let (body, _) = try readBody(startWithData: remainingData,
                                             remoteSocket: remoteSocket,
                                             contentLength: header.contentLength ?? 0)
                request.body = body

                try handler.onBodyCompleted(body: body, request: request, response: response)
                try sendResponse(socket: remoteSocket, response: response)
                
            } catch {
                guard error is Socket.Error else {
                    try sendResponse(socket: remoteSocket, response: errorResponse(code: 500, customBody: "Operation Failed - with:\n\(error)"))
                    return
                }
                throw error
            }
            
        } catch {

            guard let socketError = error as? Socket.Error else {
		        print("HttpServer::readSend() - Unexpected error...\n \(error)")
                return
	        }

            if !self.finishing {
		        print("HttpServer::readSend() error reported:\n \(socketError.description)")
            }
        }
    }

    func sendResponse(socket: Socket, response: HttpResponse) throws {
        
        guard var headerData = response.header.description.data(using: .utf8) else {
            throw HttpServerError.insufficientHeaderString
        }

        while headerData.count > 0 {
            let bytesWrite = try socket.write(from: headerData)
            guard bytesWrite > 0 else {
                throw HttpServerError.custom(string: "write failed")
            }
            headerData.removeSubrange(0..<bytesWrite)
        }

        guard var bodyData = response.data else {
            // no body
            return
        }

        while bodyData.count > 0 {
            let bytesWrite = try socket.write(from: bodyData)
            guard bytesWrite > 0 else {
                throw HttpServerError.custom(string: "write failed")
            }
            bodyData.removeSubrange(0..<bytesWrite)
        }
    }

    func errorResponse(code: Int, customBody: String? = nil, contentType: String = "text/plain") -> HttpResponse {
        let reason = HttpStatusCode.shared[code] ?? "Unknown"
        let response = HttpResponse(code: code, reason: reason)
        response.header.contentType = contentType
        if let body = customBody {
            response.data = body.data(using: .utf8)
        } else {
            response.data = "Error: \(code) \(reason)".data(using: .utf8)
        }
        return response
    }

    func readHeaderString(startWithData: Data?, remoteSocket: Socket?) throws -> (String, Data?) {
        var readBuffer = Data(capacity: bufferSize)
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
            
            guard bytesRead > 0 else {
                throw HttpServerError.insufficientHeaderString
            }
            
            buffer.append(readBuffer)

            readBuffer.count = 0
            
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
        var readBuffer = Data(capacity: bufferSize)

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
                throw HttpServerError.custom(string: "HttpServer::readBody() error - insufficient read bytes \(bytesRead) / count: \(readBuffer.count)")
            }

            bodyBuffer.append(readBuffer)

            readBuffer.count = 0
            
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

    public func finish() {
        finishing = true
        for socket in connectedSockets.values {
	        self.lockQueue.sync { [unowned self, socket] in
		        connectedSockets[socket.socketfd] = nil
		        socket.close()
	        }
	    }
        listenSocket?.close()
    }
}

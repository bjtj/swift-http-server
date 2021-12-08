//
// HttpServer.swift
// 

import Foundation
import Socket


/**
 Http Server Implementation
 */
public class HttpServer {

    /**
     Connection Filter
     */
    public typealias connectionFilter = ((Socket) -> Bool)

    /**
     Server Status
     */
    public enum Status {
        case idle
        case started
        case stopped
    }

    /**
     Http Server Status Monitoring Handler Type
     */
    public typealias monitorHandlerType = ((String?, HttpServer.Status, Error?) -> Void)

    var status: Status = .idle

    var monitorName: String?
    var finishing = false

    /**
     Is Running?
     */
    public var running: Bool {
        get {
            return _running
        }
    }
    var _running = false
    var listenSocket: Socket?
    var hostname: String?
    var port: Int
    var backlog: Int
    var reusePort: Bool
    var connectedSockets = [Int32: Socket]()
    public var connectionFilter: connectionFilter?
    
    /**
     Connected Socket Count
     */
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
     Get Actual Listening Port
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
     Set Monitoring Handler
     */
    public func monitor(monitorName: String?, monitorHandler: monitorHandlerType?) -> Void {
        self.monitorName = monitorName
        self.monitorHandler = monitorHandler
    }

    /**
     Run Http Server
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

    // onConnect
    func onConnect(remoteSocket: Socket) {
        if let filter = self.connectionFilter {
            guard filter(remoteSocket) else {
                // socket filtered
                return
            }
        }
        
        lockQueue.sync { [self, remoteSocket] in
            self.connectedSockets[remoteSocket.socketfd] = remoteSocket
        }
        
        DispatchQueue.global(qos: .default).async {
            [self, remoteSocket] in
            self.communicate(remoteSocket: remoteSocket)

            self.lockQueue.sync { [self, remoteSocket] in
                self.connectedSockets[remoteSocket.socketfd] = nil
            }
            remoteSocket.close()
        }
    }

    // Communiate
    func communicate(remoteSocket: Socket) {
        var needKeepDoing = true
        var remainingData: Data? = nil
        repeat {
            (needKeepDoing, remainingData) = readSend(remoteSocket: remoteSocket, startWithData: remainingData)
            usleep(10 * 1000)
        } while needKeepDoing
    }

    // Read request and send response
    func readSend(remoteSocket: Socket, startWithData: Data?) -> (Bool, Data?) {
        do {
            // 1. Read Header
            let (headerString, remainingDataFromHeaderRead) = try readHeaderString(startWithData: startWithData, remoteSocket: remoteSocket)
            let header = try HttpHeader.read(text: headerString)
            let request = try HttpRequest(remoteSocket: remoteSocket, header: header)

            // Get Request Handler
            guard let handler = router.dispatch(path: request.path) else {
                try sendResponse(socket: remoteSocket, response: errorResponse(statusCode: .notFound))
                return (false, nil)
            }

            if handler.dumpBody {
                request.body = Data()
            }
            
            let response = HttpResponse(statusCode: .notFound)
            
            do {
                // Handle Header Completed
                try handler.onHeaderCompleted(header: header, request: request, response: response)

                // Get Transfer Handler
                guard let transfer = try getTransfer(remoteSocket: remoteSocket, request: request, startWithData: remainingDataFromHeaderRead) else {
                    try sendResponse(socket: remoteSocket, response: errorResponse(statusCode: .badRequest, customBody: "Invalid Transfer Encoding \(request.header["Transfer-Encoding"] ?? "nil")"))
                    return (false, nil)
                }

                // 2. Read Body
                while finishing == false && transfer.status != .completed {
                    guard let data = try transfer.read() else {
                        break
                    }
                    try handler.onBodyData(data: data, request: request, response: response)
                    request.body?.append(data)
                }

                // Body Completed
                response.header["Connection"] = request.header["Connection"]
                try handler.onBodyCompleted(body: request.body, request: request, response: response)

                // 3. Send Response
                try sendResponse(socket: remoteSocket, response: response)

                // Check Continuous Handling
                let remainingDataFromBodyRead = transfer.remainingData
                return (checkKeepAlive(request: request, response: response), remainingDataFromBodyRead)
                
            } catch {
                // Operation Failed
                guard error is Socket.Error else {
                    try sendResponse(socket: remoteSocket, response: errorResponse(statusCode: .internalServerError, customBody: "Operation Failed with:\n\(error)"))
                    return (false, nil)
                }
                throw error
            }
        } catch {
            guard let socketError = error as? Socket.Error else {
                print("HttpServer::readSend() - Unexpected error...\n \(error)")
                return (false, nil)
            }
            if !finishing {
                print("HttpServer::readSend() error reported:\n \(socketError.description)")
            }
            return (false, nil)
        }
    }

    func getTransfer(remoteSocket: Socket, request: HttpRequest, startWithData: Data?) throws -> Transfer? {
        switch request.header.transferEncoding {
        case let val where val == .chunked:
            return try ChunkedTransfer(remoteSocket: remoteSocket, startWithData: startWithData)            
        default:
            // TODO: tolerable content length is ok?
            let contentLength = request.contentLength ?? 0
            return try FixedTransfer(remoteSocket: remoteSocket, contentLength: contentLength, startWithData: startWithData)
        }
    }

    func checkKeepAlive(request: HttpRequest, response: HttpResponse) -> Bool {
        return
          request.`protocol` == .http1_1 &&
          "close".caseInsensitiveCompare(request.header["Connection"] ?? "") != .orderedSame &&
          "close".caseInsensitiveCompare(response.header["Connection"] ?? "") != .orderedSame
    }

    func sendResponse(socket: Socket, response: HttpResponse) throws {
        guard var headerData = response.header.description.data(using: .utf8) else {
            throw HttpServerError.insufficientHeaderString
        }

        while headerData.count > 0 {
            let bytesWrite = try socket.write(from: headerData)
            guard bytesWrite > 0 else {
                if bytesWrite == 0 {
                    throw HttpServerError.socketClosed
                }
                throw HttpServerError.socketFailed(string: "socket write failed: \(bytesWrite)")
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
                throw HttpServerError.socketFailed(string: "socket write failed: \(bytesWrite)")
            }
            bodyData.removeSubrange(0..<bytesWrite)
        }
    }

    func errorResponse(statusCode: HttpStatusCode, customBody: String? = nil, contentType: String = "text/plain") -> HttpResponse {
        let response = HttpResponse(statusCode: statusCode)
        response.header.contentType = contentType
        if let body = customBody {
            response.data = body.data(using: .utf8)
        } else {
            response.data = "Error: \(statusCode.description)".data(using: .utf8)
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
        
        while finishing == false {
            if try remoteSocket.isReadableOrWritable(timeout: 1_000).0 == false {
                continue
            }
            
            let bytesRead = try remoteSocket.read(into: &readBuffer)
            
            guard bytesRead > 0 else {
                if bytesRead == 0 {
                    throw HttpServerError.socketClosed
                }
                throw HttpServerError.socketFailed(string: "socket read failed: \(bytesRead)")
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

    /**
     Finish Http Server
     */
    public func finish() {
        finishing = true
        for socket in connectedSockets.values {
	        self.lockQueue.sync { [self, socket] in
		        self.connectedSockets[socket.socketfd] = nil
		        socket.close()
	        }
	    }
        listenSocket?.close()
    }
}

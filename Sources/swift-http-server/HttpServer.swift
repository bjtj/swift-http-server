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
        return (hostname: hostname, port: port)
    }

    public var listeningPort: Int32 {
        return listenSocket!.listeningPort
    }

    public func route(path: String, handler: HttpRequestHandler?) {
        if handler == nil {
            self.router.unregister(path: path)
        } else {
            self.router.register(path: path, handler: handler);
        }
    }

    public func route(path: String, handler: HttpRequestClosure?) {
        if handler == nil {
            self.router.unregister(path: path)
        } else {
            self.router.register(path: path, handler: handler);
        }
    }

    func communicate(remoteSocket: Socket?) {

        do {
            let headerString = try readHeaderString(remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)
            let response = handleRequest(request: request)
            if response!.header.contentLength == nil {
                if response!.data == nil {
                    response!.header.contentLength = 0
                } else {
                    response!.header.contentLength = response!.data!.count
                }
            }
            try remoteSocket!.write(from: response!.header.description.data(using: .utf8)!)
            guard let data = response!.data else {
                return
            }
            try remoteSocket!.write(from: data)
        } catch let error {
            print("error: \(error)")
        }
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
                return HttpResponse(code: 400, reason: HttpError.shared[404])
            }
            return try handler.onHttpRequest(request: request)
        } catch let error {
            print("error: \(error)")
            return HttpResponse(code: 500, reason: HttpError.shared[500])
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

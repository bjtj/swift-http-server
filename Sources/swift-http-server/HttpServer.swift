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
    let router: Router?

    public init(port: Int = 0, backlog: Int = 5, reusePort: Bool = true) {
        self.port = port
        self.backlog = backlog
        self.reusePort = reusePort
        router = Router()
    }

    public var serverAddress: (String?, Int32?) {
        return (listenSocket?.signature!.hostname, listenSocket?.signature!.port)
    }

    

    func comm(remoteSocket: Socket?) {

        do {
            let headerString = try readHeaderString(remoteSocket: remoteSocket)
            let header = HttpHeader.read(text: headerString)
            let request = HttpRequest(remoteSocket: remoteSocket, header: header)
            let response = handleRequest(request: request)
            try remoteSocket!.write(from: response!.header.description.data(using: .utf8)!)

            guard let inputStream = response!.inputStream else {
                return
            }

            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while finishing == false && inputStream.hasBytesAvailable {
                let read = inputStream.read(buffer, maxLength: bufferSize)
                try remoteSocket!.write(from: buffer, bufSize: read)
                // transfer.write(from: data, count: read)
            }
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
            // var transfer = Transfer(remoteSocket: remoteSocket)
            if let handler = router?.dispatch(path: request.path) {
                return try handler.handle(request: request)
            } else {
                return HttpResponse(code: 400, reason: HttpError.shared[404])
            }
        } catch let error {
            print("error: \(error)")
            return HttpResponse(code: 500, reason: HttpError.shared[500])
        }
    }

    func onConnect(remoteSocket: Socket?) {
        let queue = DispatchQueue.global(qos: .default)
        queue.async { [unowned self, remoteSocket] in
            defer {
                self.onDisconnect(remoteSocket: remoteSocket)
            }
            self.comm(remoteSocket: remoteSocket)
            remoteSocket?.close()
        }
    }

    func onDisconnect(remoteSocket: Socket?) {
    }

    func loop() throws {
        listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        try listenSocket?.listen(on: port, maxBacklogSize: backlog, allowPortReuse: reusePort)
        // print((listenSocket?.signature)!)
        repeat {
            let remoteSocket = try listenSocket?.acceptClientConnection()
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

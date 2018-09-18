import Foundation
import Socket

public class HttpServer {

    var finishing = false
    var listenSocket: Socket?
    var port: Int
    var backlog: Int
    var reusePort: Bool
    var connectedSockets = [Int32: Socket]()

    public init(port: Int = 0, backlog: Int = 5, reusePort: Bool = true) {
        self.port = port
        self.backlog = backlog
        self.reusePort = reusePort
    }

    public var serverAddress: (String?, Int32?) {
        return (listenSocket?.signature!.hostname, listenSocket?.signature!.port)
    }

    func onConnect(remoteSocket: Socket?) throws {
        var data = Data(capacity: 4096)
        let bytesRead = try remoteSocket?.read(into: &data)
        // todo: read header
        // todo: route a request to the resource
        if bytesRead! > 0 {
            try remoteSocket?.write(from: data)
        }
        remoteSocket?.close()
        onDisconnect(remoteSocket: remoteSocket)
    }

    func onDisconnect(remoteSocket: Socket?) {
    }

    func loop() throws {
        listenSocket = try Socket.create(family: .inet, type: .stream, proto: .tcp)
        try listenSocket?.listen(on: port, maxBacklogSize: backlog, allowPortReuse: reusePort)
        // print((listenSocket?.signature)!)
        repeat {
            let remoteSocket = try listenSocket?.acceptClientConnection()
            try onConnect(remoteSocket: remoteSocket)
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

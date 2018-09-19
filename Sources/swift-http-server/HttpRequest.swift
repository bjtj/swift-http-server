import Socket

public class HttpRequest {
    public var remoteSocket: Socket?
    public var header: HttpHeader?

    public init(remoteSocket: Socket?, header: HttpHeader?) {
        self.remoteSocket = remoteSocket
        self.header = header
    }
}

import Socket

public class HttpRequest {
    public var remoteSocket: Socket?
    public var header: HttpHeader = HttpHeader()

    public var path: String {
        return header.firstLine.second
    }

    public init(remoteSocket: Socket?, header: HttpHeader?) {
        self.remoteSocket = remoteSocket
        self.header = header!
        self.header.specVersion = HttpSpecVersion(rawValue: self.header.firstLine.third)
    }
}

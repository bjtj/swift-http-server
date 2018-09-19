import Socket

public class HttpRequest {
    public var remoteSocket: Socket?
    private(set) var header: HttpHeader = HttpHeader()

    public init(remoteSocket: Socket?, header: HttpHeader?) {
        self.remoteSocket = remoteSocket
        self.header = header!
        self.header.specVersion = HttpSpecVersion(rawValue: self.header.firstLine.third)
    }
}

import Socket
import Foundation

public class HttpRequest {
    
    public var remoteSocket: Socket?
    public var header: HttpHeader = HttpHeader()
    public var body: Data?

    public var method: String {
        return header.firstLine.first
    }

    public var path: String {
        return header.firstLine.second
    }

    public var httpProtocol: String {
        return header.firstLine.third
    }

    public init(remoteSocket: Socket?, header: HttpHeader?) {
        self.remoteSocket = remoteSocket
        self.header = header!
        self.header.specVersion = HttpSpecVersion(rawValue: self.header.firstLine.third)
    }
}

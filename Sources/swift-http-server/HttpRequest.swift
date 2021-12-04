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

    public var contentType: String? {
        get {
            return header.contentType
        }
        set(value) {
            header.contentType = value
        }
    }

    public var contentLength: Int? {
        get {
            return header.contentLength
        }
        set(value) {
            header.contentLength = value
        }
    }

    public init(remoteSocket: Socket?, header: HttpHeader?) {
        self.remoteSocket = remoteSocket
        self.header = header!
        self.header.specVersion = HttpSpecVersion(rawValue: self.header.firstLine.third)
    }
}

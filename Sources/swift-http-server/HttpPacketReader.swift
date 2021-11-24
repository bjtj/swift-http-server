import Foundation

public class HttpPacketReaderContext {
}

public enum HttpPacketReaderType {
    case idle
    case readHeader
    case readHeaderCompleted
    case readBody
    case readBodyCompleted
}

public typealias HttpPacketReaderDelegate = ((HttpPacketReaderContext?, HttpPacketReaderType, Data?) -> Void)

public class HttpPacketReader {

    public var delegate: HttpPacketReaderDelegate?

    var lastType: HttpPacketReaderType
    var buffer: Data
    
    public init(delegate: HttpPacketReaderDelegate?) {
        self.delegate = delegate
        self.lastType = .idle
        self.buffer = Data()
    }

    public func process(data: Data?) throws -> Void {
        guard let data = data else {
            return
        }

        if let index = data.range(of: "\r\n\r\n".data(using: .utf8)!) {
            guard let header = String(data: data.subdata(in: 0..<index.first!), encoding: .utf8) else {
                throw HttpServerError.custom(string: "Unexpected error - data -> string")
            }
            delegate?(nil, .readHeaderCompleted, header.data(using: .utf8))
        }
        
    }
}

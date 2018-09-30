import Foundation

public class HttpResponse {
    public var header = HttpHeader()
    public var _data: Data?
    public var data: Data? {
        get {
            return _data
        }
        set(newValue) {
            if let data = newValue {
                header.contentLength = data.count
            } else {
                header.contentLength = 0
            }
            _data = newValue
        }
    }
    public var _stream: InputStream?
    public var stream: InputStream? {
        get {
            return _stream
        }
        set(newValue) {
            _stream = newValue
        }
    }

    public init(specVersion: HttpSpecVersion = .HTTP1_1, code: Int) {
        header.specVersion = specVersion
        header.firstLine.first = specVersion.rawValue
        self.code = code
        self.reason = HttpStatusCode.shared[code]!
    }

    public init(specVersion: HttpSpecVersion = .HTTP1_1, code: Int, reason: String?) {
        header.specVersion = specVersion
        header.firstLine.first = specVersion.rawValue
        self.code = code
        self.reason = reason
    }

    public var code: Int {
        get {
            return Int(header.firstLine.second)!
        }
        set(value) {
            header.firstLine.second = "\(value)"
        }
    }

    public var reason: String? {
        get {
            return header.firstLine.third
        }
        set(value) {
            header.firstLine.third = value!
        }
    }
}

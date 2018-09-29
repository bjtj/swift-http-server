import Foundation

public class HttpResponse {
    private(set) var header: HttpHeader = HttpHeader()
    public var data: Data?

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

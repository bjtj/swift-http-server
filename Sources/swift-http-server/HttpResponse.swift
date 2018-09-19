import Foundation

public class HttpResponse {
    var header: HttpHeader?
    var inputStream: InputStream?

    init(specVersion: String = "HTTP/1.1", code: Int, reason: String?) {
        header!.firstLine.first = specVersion
        self.code = code
        self.reason = reason
    }

    var code: Int {
        get {
            return Int(header!.firstLine.second)!
        }
        set(value) {
            header?.firstLine.second = "\(value)"
        }
    }

    var reason: String? {
        get {
            return header!.firstLine.third
        }
        set(value) {
            header!.firstLine.third = value!
        }
    }
}

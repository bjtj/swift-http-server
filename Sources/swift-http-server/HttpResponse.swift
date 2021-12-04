import Foundation


/**
 HttpResponse
 */
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

    public var contentType: String? {
        get {
            return header.contentType
        }
        set(value) {
            header.contentType = value
        }
    }

    var _status: HttpStatusCode?
     public var status: HttpStatusCode? {
         get {
             return _status
        }

        set(value) {
            guard let statusCode = value else {
                _status = nil
                code = -1
                reason = "Unknown"
                return
            }
            _status = statusCode
            code = statusCode.rawValue.code
            reason = statusCode.rawValue.reason
        }
    }

    public init(specVersion: HttpSpecVersion = .HTTP1_1, statusCode: HttpStatusCode) {
        header.specVersion = specVersion
        header.firstLine.first = specVersion.rawValue
        status = statusCode
    }

    @available(*, deprecated, renamed: "status")
    public func setStatus(code: Int, reason: String? = nil) {
        status = .custom(code, reason ?? "Unknown")
    }

   
}

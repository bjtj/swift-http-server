
public class HttpStatusCode {

    private static var _shared: HttpStatusCode?
    public static var shared: HttpStatusCode {
        get {
            if _shared == nil {
                _shared = HttpStatusCode()
            }
            return _shared!
        }
    }

    var table: [Int: String] = [:]

    private init() {
        self[100] = "Continue"
        self[101] = "Switching Protocols"
        self[200] = "OK"
        self[201] = "Created"
        self[202] = "Accepted"
        self[203] = "Non-Authoritative Information"
        self[204] = "No Content"
        self[205] = "Reset Content"
        self[206] = "Partial Content"
        self[300] = "Multiple Choices"
        self[301] = "Moved Permanently"
        self[302] = "Found"
        self[303] = "See Other"
        self[304] = "Not Modified"
        self[305] = "Use Proxy"
        self[306] = "(Unused)"
        self[307] = "Temporary Redirect"
        self[400] = "Bad Request"
        self[401] = "Unauthorized"
        self[402] = "Payment Required"
        self[403] = "Forbidden"
        self[404] = "Not Found"
        self[405] = "Method Not Allowed"
        self[406] = "Not Acceptable"
        self[407] = "Proxy Authentication Required"
        self[408] = "Request Timeout"
        self[409] = "Conflict"
        self[410] = "Gone"
        self[411] = "Length Required"
        self[412] = "Precondition Failed"
        self[413] = "Request Entity Too Large"
        self[414] = "Request-URI Too Long"
        self[415] = "Unsupported Media Type"
        self[416] = "Requested Range Not Satisfiable"
        self[417] = "Expectation Failed"
        self[500] = "Internal Server Error"
        self[501] = "Not Implemented"
        self[502] = "Bad Gateway"
        self[503] = "Service Unavailable"
        self[504] = "Gateway Timeout"
        self[505] = "HTTP Version Not Supported"
    }

    public subscript(code: Int) -> String? {
        get {
            return table[code]
        }
        set(reason) {
            table[code] = reason
        }
    }
}

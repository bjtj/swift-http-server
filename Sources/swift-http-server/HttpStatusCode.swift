
public class HttpStatusCode {

    private static var _shared: HttpStatusCode?
    public static var shared: HttpStatusCode {
        get {
            if _shared == nil {
                _shared = HttpStatusCode()
                _shared![100] = "Continue"
		        _shared![101] = "Switching Protocols"
		        _shared![200] = "OK"
		        _shared![201] = "Created"
		        _shared![202] = "Accepted"
		        _shared![203] = "Non-Authoritative Information"
		        _shared![204] = "No Content"
		        _shared![205] = "Reset Content"
		        _shared![206] = "Partial Content"
		        _shared![300] = "Multiple Choices"
		        _shared![301] = "Moved Permanently"
		        _shared![302] = "Found"
		        _shared![303] = "See Other"
		        _shared![304] = "Not Modified"
		        _shared![305] = "Use Proxy"
		        _shared![306] = "(Unused)"
		        _shared![307] = "Temporary Redirect"
		        _shared![400] = "Bad Request"
		        _shared![401] = "Unauthorized"
		        _shared![402] = "Payment Required"
		        _shared![403] = "Forbidden"
		        _shared![404] = "Not Found"
		        _shared![405] = "Method Not Allowed"
		        _shared![406] = "Not Acceptable"
		        _shared![407] = "Proxy Authentication Required"
		        _shared![408] = "Request Timeout"
		        _shared![409] = "Conflict"
		        _shared![410] = "Gone"
		        _shared![411] = "Length Required"
		        _shared![412] = "Precondition Failed"
		        _shared![413] = "Request Entity Too Large"
		        _shared![414] = "Request-URI Too Long"
		        _shared![415] = "Unsupported Media Type"
		        _shared![416] = "Requested Range Not Satisfiable"
		        _shared![417] = "Expectation Failed"
		        _shared![500] = "Internal Server Error"
		        _shared![501] = "Not Implemented"
		        _shared![502] = "Bad Gateway"
		        _shared![503] = "Service Unavailable"
		        _shared![504] = "Gateway Timeout"
		        _shared![505] = "HTTP Version Not Supported"
            }
            return _shared!
        }
    }

    var table: [Int: String] = [:]

    private init() {
    }

    subscript(code: Int) -> String? {
        get {
            return table[code]
        }
        set(reason) {
            table[code] = reason
        }
    }
}

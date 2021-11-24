import Foundation

public class HttpStatusCode {

    static var shared = HttpStatusCode()

    var table: [Int: String] = [:]

    private init() {
        table[100] = "Continue"
	table[101] = "Switching Protocols"
	table[200] = "OK"
	table[201] = "Created"
	table[202] = "Accepted"
	table[203] = "Non-Authoritative Information"
	table[204] = "No Content"
	table[205] = "Reset Content"
	table[206] = "Partial Content"
	table[300] = "Multiple Choices"
	table[301] = "Moved Permanently"
	table[302] = "Found"
	table[303] = "See Other"
	table[304] = "Not Modified"
	table[305] = "Use Proxy"
	table[306] = "(Unused)"
	table[307] = "Temporary Redirect"
	table[400] = "Bad Request"
	table[401] = "Unauthorized"
	table[402] = "Payment Required"
	table[403] = "Forbidden"
	table[404] = "Not Found"
	table[405] = "Method Not Allowed"
	table[406] = "Not Acceptable"
	table[407] = "Proxy Authentication Required"
	table[408] = "Request Timeout"
	table[409] = "Conflict"
	table[410] = "Gone"
	table[411] = "Length Required"
	table[412] = "Precondition Failed"
	table[413] = "Request Entity Too Large"
	table[414] = "Request-URI Too Long"
	table[415] = "Unsupported Media Type"
	table[416] = "Requested Range Not Satisfiable"
	table[417] = "Expectation Failed"
	table[500] = "Internal Server Error"
	table[501] = "Not Implemented"
	table[502] = "Bad Gateway"
	table[503] = "Service Unavailable"
	table[504] = "Gateway Timeout"
	table[505] = "HTTP Version Not Supported"
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

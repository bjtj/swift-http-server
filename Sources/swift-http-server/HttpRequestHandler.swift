

/**
 HttpRequestClojure
 */
public typealias HttpRequestClosure = (HttpRequest) throws -> HttpResponse?

/**
 HttpRequestDelegate
 */
public protocol HttpRequestDelegate {
    func onHttpRequest(request: HttpRequest) throws -> HttpResponse?
}

/**
 HttpRequestHandler
 */
public class HttpRequestHandler : HttpRequestDelegate {

    var closureHandler: HttpRequestClosure?
    
    public init(with: HttpRequestClosure?) {
        self.closureHandler = with
    }

    /**
     onHttpRequest
     */
    public func onHttpRequest(request: HttpRequest) throws -> HttpResponse? {
        guard let closure = closureHandler else {
            throw HttpServerError.operationFailed(string: "No request handling function found")
        }
        return try closure(request)
    }
}

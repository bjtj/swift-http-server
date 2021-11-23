
/**
 
 */
public enum HttpRequestHandlerError: Error {
    case NoOperationError
}

/**
 
 */
public typealias HttpRequestClosure = (HttpRequest) throws -> HttpResponse?

/**
 
 */
public protocol HttpRequestDelegate {
    func onHttpRequest(request: HttpRequest) throws -> HttpResponse?
}

/**
 
 */
public class HttpRequestHandler : HttpRequestDelegate {

    var closureHandler: HttpRequestClosure?
    
    public init(with: HttpRequestClosure?) {
        self.closureHandler = with
    }

    /**
     
     */
    public func onHttpRequest(request: HttpRequest) throws -> HttpResponse? {
        guard let closure = closureHandler else {
            throw HttpRequestHandlerError.NoOperationError
        }
        return try closure(request)
    }
}

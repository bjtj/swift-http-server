
public enum HttpRequestHandlerError: Error {
    case NoOperationError
}

public typealias HttpRequestClosure = (_ request: HttpRequest?) throws -> HttpResponse?

public class HttpRequestHandler {

    var closureHandler: HttpRequestClosure?
    
    public init(with: HttpRequestClosure?) {
        self.closureHandler = with
    }
    
    func handle(request: HttpRequest) throws -> HttpResponse? {
        guard let closure = closureHandler else {
            throw HttpRequestHandlerError.NoOperationError
        }
        return try closure(request)
    }
}

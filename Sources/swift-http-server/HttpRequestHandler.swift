
public typealias HttpRequestClosure = (_ request: HttpRequest?) throws -> HttpResponse?

public protocol HttpRequestHandler {
    func handle(request: HttpRequest) throws -> HttpResponse?
}

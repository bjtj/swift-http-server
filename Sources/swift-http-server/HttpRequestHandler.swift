
public protocol HttpRequestHandler {
    func handle(request: HttpRequest?) throws -> HttpResponse?
}

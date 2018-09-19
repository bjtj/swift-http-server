
public protocol HttpRequestHandler {
    func handle(req: HttpRequest?) throws -> HttpResponse?
}

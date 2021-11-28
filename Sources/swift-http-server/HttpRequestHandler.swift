import Foundation

/**
 HttpRequestHandler
 */
public protocol HttpRequestHandler {
    func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws
    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws
}

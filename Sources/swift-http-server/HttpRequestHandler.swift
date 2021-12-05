import Foundation

/**
 HttpRequestHandler
 */
public protocol HttpRequestHandler {
    var dumpBody: Bool { get }
    func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws
    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws
}

extension HttpRequestHandler {
    func onBodyData(data: Data?, request: HttpRequest, response: HttpResponse) throws {
        // optional
    }
}

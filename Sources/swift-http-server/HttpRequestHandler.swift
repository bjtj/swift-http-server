//
// HttpRequestHandler.swift
//

import Foundation

/**
 HttpRequestHandler
 */
public protocol HttpRequestHandler {
    /**
     Enable dump body if return value is true
     */
    var dumpBody: Bool { get }
    /**
     When header completed
     */
    func onHeaderCompleted(header: HttpHeader, request: HttpRequest, response: HttpResponse) throws
    /**
     When body completed
     */
    func onBodyCompleted(body: Data?, request: HttpRequest, response: HttpResponse) throws
}

extension HttpRequestHandler {
    /**
     When partial body data come
     */
    func onBodyData(data: Data?, request: HttpRequest, response: HttpResponse) throws {
        // optional
    }
}

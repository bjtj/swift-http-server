//
// HttpRequest.swift
// 

import Socket
import Foundation

/**
 Http Request
 */
public class HttpRequest {

    /**
     Remote socket
     */
    public var remoteSocket: Socket?
    /**
     Header of http request
     */
    public var header: HttpHeader = HttpHeader()
    /**
     Body data
     */
    public var body: Data?

    var urlPathParser: URLPathParser

    /**
     Method
     */
    public var method: String {
        return header.firstLine.first
    }

    /**
     URI
     */
    public var uri: String {
        return header.firstLine.second
    }

    /**
     Path of URI
     */
    public var path: String {
        return urlPathParser.path
    }

    /**
     Path Fragment
     */
    public var pathFragment: String? {
        return urlPathParser.fragment
    }

    /**
     Http Protocol
     */
    public var `protocol`: HttpSpecVersion? {
        return HttpSpecVersion(rawValue: header.firstLine.third)
    }

    /**
     Content Type
     */
    public var contentType: String? {
        get {
            return header.contentType
        }
        set(value) {
            header.contentType = value
        }
    }

    /**
     Content Length
     */
    public var contentLength: Int? {
        get {
            return header.contentLength
        }
        set(value) {
            header.contentLength = value
        }
    }

    public init(remoteSocket: Socket?, header: HttpHeader) throws {
        self.remoteSocket = remoteSocket
        self.header = header
        guard let protocolVersion = HttpSpecVersion(rawValue: header.firstLine.third) else {
            throw HttpServerError.unknownProtocolVersion(string: "Unknown Protocol - \(header.firstLine.third)")
        }
        self.header.specVersion = protocolVersion
        urlPathParser = URLPathParser(string: header.firstLine.second)
    }

    /**
     Parameter Names
     */
    public func parameterNames() -> [String] {
        return urlPathParser.keys(of: .queryParameter)
    }

    /**
     Query Parameters
     */
    public func parameter(_ key: String) -> String? {
        return urlPathParser.parameter(key)
    }

    /**
     Query Parameters
     */
    public func parameters(_ key: String) -> [String]? {
        return urlPathParser.parameters(key)
    }

    /**
     Path Parameter
     */
    public func pathParameter(_ key: String) -> String? {
        return urlPathParser.parameter(key, of: .pathParameter)
    }

    /**
     Path Parameters
     */
    public func pathParameters(_ key: String) -> [String]? {
        return urlPathParser.parameters(key, of: .pathParameter)
    }
}

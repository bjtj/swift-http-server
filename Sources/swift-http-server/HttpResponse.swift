//
// HttpResponse.swift
// 

import Foundation


/**
 HttpResponse
 */
public class HttpResponse {

    /**
     Http Header
     */
    public var header = HttpHeader()
    
    var _data: Data?
    /**
     Content Data and set content length with data size
     TODO: support other transfer types
     */
    public var data: Data? {
        get {
            return _data
        }
        set(newValue) {
            if let data = newValue {
                header.contentLength = data.count
            } else {
                header.contentLength = 0
            }
            _data = newValue
        }
    }

    /**
     Get/Set code part of firstline
     */
    public var code: Int {
        get {
            return Int(header.firstLine.second)!
        }
        set(value) {
            header.firstLine.second = "\(value)"
        }
    }

    /**
     Get/Set reason part of firstline
     */
    public var reason: String? {
        get {
            return header.firstLine.third
        }
        set(value) {
            header.firstLine.third = value!
        }
    }

    /**
     Get/Set content type of http header
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
     Get/Set Http Status (code & reason)
     */
    public var status: HttpStatusCode? {
        get {
            return _status
        }

        set(value) {
            guard let statusCode = value else {
                _status = nil
                code = -1
                reason = "Unknown"
                return
            }
            _status = statusCode
            code = statusCode.rawValue.code
            reason = statusCode.rawValue.reason
        }
    }
    var _status: HttpStatusCode?

    public init(specVersion: HttpSpecVersion = .http1_1, statusCode: HttpStatusCode) {
        header.specVersion = specVersion
        header.firstLine.first = specVersion.rawValue
        status = statusCode
    }

    /**
     Set Status (code & reason)
     @deprecated use `status` computed variable
     */
    @available(*, deprecated, renamed: "status")
    public func setStatus(code: Int, reason: String? = nil) {
        status = .custom(code, reason ?? "Unknown")
    }

    
}

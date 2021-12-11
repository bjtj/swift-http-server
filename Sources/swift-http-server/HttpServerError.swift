//
// HttpServerError.swift
// 

import Foundation

/**
 HttpServerError
 */
public enum HttpServerError: Error {
    case socketClosed
    case socketFailed(string: String)
    case alreadyRunning
    case insufficientHeaderString
    case operationFailed(string: String)
    case custom(string: String)
    case illegalArgument(string: String)
    case unknownProtocolVersion(string: String)
    case httpResponse(status: HttpStatusCode, fields: [String:String]?, data: Data?)
}

//
// HttpServerError.swift
// 

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
}

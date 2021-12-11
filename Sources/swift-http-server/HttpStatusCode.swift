// 
// HttpStatusCode.swift
// 

import Foundation


/**
 Http Status Code
 */
public enum HttpStatusCode: Error {

    case custom(Int, String)
    case `continue`                  // 100 Continue
    case switchingProtocols          // 101 Switching Protocols
    case ok                          // 200 OK
    case created                     // 201 Created
    case accepted                    // 202 Accepted
    case nonAuthoritativeInformation // 203 Non-Authoritative Information
    case noContent                   // 204 No Content
    case resetContent                // 205 Reset Content
    case partialContent              // 206 Partial Content
    case multipleChoices             // 300 Multiple Choices
    case movedPermanently            // 301 Moved Permanently
    case found                       // 302 Found
    case seeOther                    // 303 See Other
    case notModified                 // 304 Not Modified
    case useProxy                    // 305 Use Proxy
    case unused                      // 306 (Unused)
    case temporaryRedirect           // 307 Temporary Redirect
    case badRequest                  // 400 Bad Request
    case unauthorized                // 401 Unauthorized
    case paymentRequired             // 402 Payment Required
    case forbidden                   // 403 Forbidden
    case notFound                    // 404 Not Found
    case methodNotAllowed            // 405 Method Not Allowed
    case notAcceptable               // 406 Not Acceptable
    case proxyAuthenticationRequired // 407 Proxy Authentication Required
    case requestTimeout              // 408 Request Timeout
    case conflict                    // 409 Conflict
    case gone                        // 410 Gone
    case lengthRequired              // 411 Length Required
    case preconditionFailed          // 412 Precondition Failed
    case requestEntityTooLarge       // 413 Request Entity Too Large
    case requestURITooLong           // 414 Request-URI Too Long
    case unsupportedMediaType        // 415 Unsupported Media Type
    case requestedRangeNotSatisfiable // 416 Requested Range Not Satisfiable
    case expectationFailed            // 417 Expectation Failed
    case internalServerError          // 500 Internal Server Error
    case notImplemented               // 501 Not Implemented
    case badGateway                   // 502 Bad Gateway
    case serviceUnavailable           // 503 Service Unavailable
    case gatewayTimeout               // 504 Gateway Timeout
    case httpVersionNotSupported // 505 HTTP Version Not Supported
    

    struct Code : Equatable {

        let code: Int
        let reason: String

        static func == (l: Code, r: Code) -> Bool {
            return l.code == r.code && l.reason == r.reason
        }

        static var `continue` : HttpStatusCode.Code { return Code(code: 100, reason: "Continue") }
        static var switchingProtocols : HttpStatusCode.Code { return Code(code: 101, reason: "Switching Protocols") }
        static var ok : HttpStatusCode.Code { return Code(code: 200, reason: "OK") }
        static var created : HttpStatusCode.Code { return Code(code: 201, reason: "Created") }
        static var accepted : HttpStatusCode.Code { return Code(code: 202, reason: "Accepted") }
        static var nonAuthoritativeInformation  : HttpStatusCode.Code { return Code(code: 203, reason: "Non-Authoritative Information") }
        static var noContent : HttpStatusCode.Code { return Code(code: 204, reason: "No Content") }
        static var resetContent : HttpStatusCode.Code { return Code(code: 205, reason: "Reset Content") }
        static var partialContent : HttpStatusCode.Code { return Code(code: 206, reason: "Partial Content") }
        static var multipleChoices : HttpStatusCode.Code { return Code(code: 300, reason: "Multiple Choices") }
        static var movedPermanently : HttpStatusCode.Code { return Code(code: 301, reason: "Moved Permanently") }
        static var found : HttpStatusCode.Code { return Code(code: 302, reason: "Found") }
        static var seeOther : HttpStatusCode.Code { return Code(code: 303, reason: "See Other") }
        static var notModified : HttpStatusCode.Code { return Code(code: 304, reason: "Not Modified") }
        static var useProxy : HttpStatusCode.Code { return Code(code: 305, reason: "Use Proxy") }
        static var unused : HttpStatusCode.Code { return Code(code: 306, reason: "(Unused)") }
        static var temporaryRedirect : HttpStatusCode.Code { return Code(code: 307, reason: "Temporary Redirect") }
        static var badRequest : HttpStatusCode.Code { return Code(code: 400, reason: "Bad Request") }
        static var unauthorized : HttpStatusCode.Code { return Code(code: 401, reason: "Unauthorized") }
        static var paymentRequired : HttpStatusCode.Code { return Code(code: 402, reason: "Payment Required") }
        static var forbidden : HttpStatusCode.Code { return Code(code: 403, reason: "Forbidden") }
        static var notFound : HttpStatusCode.Code { return Code(code: 404, reason: "Not Found") }
        static var methodNotAllowed : HttpStatusCode.Code { return Code(code: 405, reason: "Method Not Allowed") }
        static var notAcceptable : HttpStatusCode.Code { return Code(code: 406, reason: "Not Acceptable") }
        static var proxyAuthenticationRequired : HttpStatusCode.Code { return Code(code: 407, reason: "Proxy Authentication Required") }
        static var requestTimeout : HttpStatusCode.Code { return Code(code: 408, reason: "Request Timeout") }
        static var conflict : HttpStatusCode.Code { return Code(code: 409, reason: "Conflict") }
        static var gone : HttpStatusCode.Code { return Code(code: 410, reason: "Gone") }
        static var lengthRequired : HttpStatusCode.Code { return Code(code: 411, reason: "Length Required") }
        static var preconditionFailed : HttpStatusCode.Code { return Code(code: 412, reason: "Precondition Failed") }
        static var requestEntityTooLarge : HttpStatusCode.Code { return Code(code: 413, reason: "Request Entity Too Large") }
        static var requestURITooLong  : HttpStatusCode.Code { return Code(code: 414, reason: "Request-URI Too Long") }
        static var unsupportedMediaType : HttpStatusCode.Code { return Code(code: 415, reason: "Unsupported Media Type") }
        static var requestedRangeNotSatisfiable : HttpStatusCode.Code { return Code(code: 416, reason: "Requested Range Not Satisfiable") }
        static var expectationFailed : HttpStatusCode.Code { return Code(code: 417, reason: "Expectation Failed") }
        static var internalServerError : HttpStatusCode.Code { return Code(code: 500, reason: "Internal Server Error") }
        static var notImplemented : HttpStatusCode.Code { return Code(code: 501, reason: "Not Implemented") }
        static var badGateway : HttpStatusCode.Code { return Code(code: 502, reason: "Bad Gateway") }
        static var serviceUnavailable : HttpStatusCode.Code { return Code(code: 503, reason: "Service Unavailable") }
        static var gatewayTimeout : HttpStatusCode.Code { return Code(code: 504, reason: "Gateway Timeout") }
        static var httpVersionNotSupported : HttpStatusCode.Code { return Code(code: 505, reason: "HTTP Version Not Supported") }
    }

    typealias RawValue = Code

    var rawValue: RawValue {
        switch self {
        case .custom(let code, let reason):
            return Code(code: code, reason: reason)
        case .`continue`: return Code.`continue`
        case .switchingProtocols: return Code.switchingProtocols
        case .ok: return Code.ok
        case .created: return Code.created
        case .accepted: return Code.accepted
        case .nonAuthoritativeInformation : return Code.nonAuthoritativeInformation 
        case .noContent: return Code.noContent
        case .resetContent: return Code.resetContent
        case .partialContent: return Code.partialContent
        case .multipleChoices: return Code.multipleChoices
        case .movedPermanently: return Code.movedPermanently
        case .found: return Code.found
        case .seeOther: return Code.seeOther
        case .notModified: return Code.notModified
        case .useProxy: return Code.useProxy
        case .unused: return Code.unused
        case .temporaryRedirect: return Code.temporaryRedirect
        case .badRequest: return Code.badRequest
        case .unauthorized: return Code.unauthorized
        case .paymentRequired: return Code.paymentRequired
        case .forbidden: return Code.forbidden
        case .notFound: return Code.notFound
        case .methodNotAllowed: return Code.methodNotAllowed
        case .notAcceptable: return Code.notAcceptable
        case .proxyAuthenticationRequired: return Code.proxyAuthenticationRequired
        case .requestTimeout: return Code.requestTimeout
        case .conflict: return Code.conflict
        case .gone: return Code.gone
        case .lengthRequired: return Code.lengthRequired
        case .preconditionFailed: return Code.preconditionFailed
        case .requestEntityTooLarge: return Code.requestEntityTooLarge
        case .requestURITooLong : return Code.requestURITooLong 
        case .unsupportedMediaType: return Code.unsupportedMediaType
        case .requestedRangeNotSatisfiable: return Code.requestedRangeNotSatisfiable
        case .expectationFailed: return Code.expectationFailed
        case .internalServerError: return Code.internalServerError
        case .notImplemented: return Code.notImplemented
        case .badGateway: return Code.badGateway
        case .serviceUnavailable: return Code.serviceUnavailable
        case .gatewayTimeout: return Code.gatewayTimeout
        case .httpVersionNotSupported: return Code.httpVersionNotSupported
        }
    }

    init?(code: Int, reason: String) {
        self = .custom(code, reason)
    }

    init?(rawValue: Int) {
        switch rawValue {
        case 100: self = .`continue`
        case 101: self = .switchingProtocols
        case 200: self = .ok
        case 201: self = .created
        case 202: self = .accepted
        case 203: self = .nonAuthoritativeInformation 
        case 204: self = .noContent
        case 205: self = .resetContent
        case 206: self = .partialContent
        case 300: self = .multipleChoices
        case 301: self = .movedPermanently
        case 302: self = .found
        case 303: self = .seeOther
        case 304: self = .notModified
        case 305: self = .useProxy
        case 306: self = .unused
        case 307: self = .temporaryRedirect
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 402: self = .paymentRequired
        case 403: self = .forbidden
        case 404: self = .notFound
        case 405: self = .methodNotAllowed
        case 406: self = .notAcceptable
        case 407: self = .proxyAuthenticationRequired
        case 408: self = .requestTimeout
        case 409: self = .conflict
        case 410: self = .gone
        case 411: self = .lengthRequired
        case 412: self = .preconditionFailed
        case 413: self = .requestEntityTooLarge
        case 414: self = .requestURITooLong 
        case 415: self = .unsupportedMediaType
        case 416: self = .requestedRangeNotSatisfiable
        case 417: self = .expectationFailed
        case 500: self = .internalServerError
        case 501: self = .notImplemented
        case 502: self = .badGateway
        case 503: self = .serviceUnavailable
        case 504: self = .gatewayTimeout
        case 505: self = .httpVersionNotSupported
        default:
            return nil
        }
    }

    var description: String {
        return "\(rawValue.code) \(rawValue.reason)"
    }

}

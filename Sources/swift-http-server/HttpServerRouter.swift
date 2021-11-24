import Foundation


extension String {
    public var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}


/**
 Router
 // TODO: regex or wildcard match support
 */
public class HttpServerRouter {
    var table: [String : HttpRequestHandlerDelegate] = [:]

    subscript(path: String) -> HttpRequestHandlerDelegate? {
        get {
            return dispatch(path: path)
        }
    }

    /**
     register router
     */
    public func register(pattern: String, handler: HttpRequestHandlerDelegate?) throws {
        table[pattern] = handler
    }

    /**
     unregister router
     */
    public func unregister(pattern: String) throws {
        table[pattern] = nil
    }

    /**
     dispatch router
     */
    public func dispatch(path: String) -> HttpRequestHandlerDelegate? {
        // TODO: regex or wildcard match
        for (pattern, handler) in table {
            if pattern == path {
                return handler
            }
        }
        return nil
    }
}

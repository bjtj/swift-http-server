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
public class Router {
    var table: [String : HttpRequestHandler] = [:]

    subscript(path: String) -> HttpRequestHandler? {
        get {
            return dispatch(path: path)
        }
    }

    /**
     register router
     */
    public func register(pattern: String, handler: HttpRequestHandler?) throws {
        table[pattern] = handler
    }

    /**
     register router
     */
    public func register(pattern: String, handler: HttpRequestClosure?) throws {
        table[pattern] = HttpRequestHandler(with: handler)
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
    public func dispatch(path: String) -> HttpRequestHandler? {
        // TODO: regex or wildcard match
        for (pattern, handler) in table {
            if pattern == path {
                return handler
            }
        }
        return nil
    }
}

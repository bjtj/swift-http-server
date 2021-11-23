import Foundation

/**
 
 */
public enum RouterError: Error {
    case invalidPattern
}


/**
 
 */
extension String {
    public var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}


/**
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
     register
     */
    public func register(pattern: String, handler: HttpRequestHandler?) throws {
        table[pattern] = handler
    }

    /**
     register
     */
    public func register(pattern: String, handler: HttpRequestClosure?) throws {
        table[pattern] = HttpRequestHandler(with: handler)
    }

    /**
     unregister
     */
    public func unregister(pattern: String) throws {
        table[pattern] = nil
    }

    /**
     dispatch
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

import Foundation


/**
 // TODO: proper wildcard match
 */
class Matcher {
    let pattern: String
    let prefix: String?
    var handler: HttpRequestHandler

    init(pattern: String, handler: HttpRequestHandler) {
        self.pattern = pattern
        self.handler = handler

        if pattern.hasSuffix("**") {
            prefix = String(pattern[..<pattern.index(pattern.endIndex, offsetBy: -2)])
        } else {
            prefix = nil
        }
    }

    // TODO: proper wildcard match
    func match(path: String) -> Bool {
        if let prefix = prefix {
            return path.hasPrefix(prefix)
        }
        return pattern == path
    }
}

/**
 Router
 */
public class HttpServerRouter {

    var table = [Matcher]()
    
    subscript(path: String) -> HttpRequestHandler? {
        get {
            return dispatch(path: path)
        }
    }

    /**
     register router
     */
    public func register(pattern: String, handler: HttpRequestHandler?) throws {

        guard let handler = handler else {
            throw HttpServerError.illegalArgument(string: "handler is nil")
        }
        
        for matcher in table {
            if matcher.pattern == pattern {
                matcher.handler = handler
                return
            }
        }
        table.append(Matcher(pattern: pattern, handler: handler))
    }

    /**
     unregister router
     */
    public func unregister(pattern: String) {
        for (i, matcher) in table.enumerated() {
            if matcher.pattern == pattern {
                table.remove(at: i)
                return
            }
        }
    }

    /**
     dispatch router
     */
    public func dispatch(path: String) -> HttpRequestHandler? {
        return table.first(where: { $0.match(path: path) })?.handler
    }
}

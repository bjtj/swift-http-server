//
// HttpServerRouter.swift
// 

import Foundation


/**
 // TODO: proper wildcard match
 */
class Matcher {
    let exactMatch: Bool
    let pattern: String
    let prefix: String?
    let suffix: String?
    var handler: HttpRequestHandler
    let depth: Int

    init(pattern: String, handler: HttpRequestHandler) throws {
        guard pattern.isEmpty == false else {
            throw HttpServerError.custom(string: "Empty Pattern is not allowed")
        }

        guard pattern.hasPrefix("/") else {
            throw HttpServerError.custom(string: "pattern is not start with /")
        }
        
        self.pattern = pattern
        self.handler = handler

        let components = pattern.components(separatedBy: "**")
        
        if components.count > 2 {
            throw HttpServerError.custom(string: "Not allowed ** more than one")
        }

        depth = pattern.components(separatedBy: "/").count - 1

        if components.count == 2 {
            prefix = components[0].isEmpty ? nil : components[0]
            suffix = components[1].isEmpty ? nil : components[1]
            exactMatch = false
        } else {
            prefix = nil
            suffix = nil
            exactMatch = true
        }
    }

    // TODO: proper wildcard match
    func match(path: String) -> Bool {
        if let prefix = prefix, let suffix = suffix {
            return path.hasPrefix(prefix) && path.hasSuffix(suffix)
        }

        if let prefix = prefix {
            return path.hasPrefix(prefix)
        }

        if let suffix = suffix {
            return path.hasSuffix(suffix)
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
     Register route
     - Parameters pattern exact matching pattern or ** wildcard pattern
     - Parameters handler handler for http request
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
        
        var list = [Matcher]()
        list.append(contentsOf: table)
        list.append(try Matcher(pattern: pattern, handler: handler))
        var exactMatched = list.filter { $0.exactMatch }
        var notExactMatched = list.filter { !$0.exactMatch }
        exactMatched.sort(by: { $0.depth > $1.depth })
        notExactMatched.sort(by: { $0.depth > $1.depth })
        table = exactMatched + notExactMatched
    }

    /**
     Unregister route
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
     Dispatch handler with path
     */
    public func dispatch(path: String) -> HttpRequestHandler? {
        return table.first(where: { $0.match(path: path) })?.handler
    }
}

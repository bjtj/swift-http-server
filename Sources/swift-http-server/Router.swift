import Foundation


public enum RouterError: Error {
    case invalidPattern
}


extension String {
    public var fullRange: NSRange {
        return NSRange(location: 0, length: self.count)
    }
}


public class ResourceProvider {
}


public class Router {
    var table: [NSRegularExpression:HttpRequestHandler] = [:]

    subscript(path: String) -> HttpRequestHandler? {
        get {
            return dispatch(path: path)
        }
    }

    public func register(pattern: String, handler: HttpRequestHandler?) throws {
        table[try toRegex(pattern: pattern)] = handler
    }

    public func register(pattern: String, handler: HttpRequestClosure?) throws {
        table[try toRegex(pattern: pattern)] = HttpRequestHandler(with: handler)
    }

    public func unregister(pattern: String) throws {
        table[try toRegex(pattern: pattern)] = nil
    }

    public func dispatch(path: String) -> HttpRequestHandler? {
        for (pattern, handler) in table {
            if pattern.matches(in: path, options: [], range: path.fullRange).isEmpty == false {
                return handler
            }
        }
        return nil
    }

    func toRegex(pattern: String) throws -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: [])
        } catch {
            throw RouterError.invalidPattern
        }
    }
}

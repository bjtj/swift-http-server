public class ResourceProvider {
}

public class Router {
    var table: [String: HttpRequestHandler] = [:]

    subscript(path: String) -> HttpRequestHandler? {
        get {
            return table[path]
        }
        set(newHandler) {
            table[path] = newHandler
        }
    }

    public func register(path: String, handler: HttpRequestHandler?) {
        table[path] = handler
    }

    public func unregister(path: String) {
        table[path] = nil
    }

    public func dispatch(path: String) -> HttpRequestHandler? {
        return table[path]
    }
}

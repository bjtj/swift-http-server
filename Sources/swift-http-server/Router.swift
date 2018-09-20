public class ResourceProvider {
}

public class Router {
    var table: [String: HttpRequestClosure] = [:]

    subscript(path: String) -> HttpRequestClosure? {
        get {
            return table[path]
        }
        set(newHandler) {
            table[path] = newHandler
        }
    }

    public func register(path: String, handler: HttpRequestClosure?) {
        table[path] = handler
    }

    public func unregister(path: String) {
        table[path] = nil
    }

    public func dispatch(path: String) -> HttpRequestClosure? {
        return table[path]
    }
}

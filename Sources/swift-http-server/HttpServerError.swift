

/**
 HttpServerError
 */
public enum HttpServerError: Error {
    case insufficientHeaderString
    case operationFailed(string: String)
    case custom(string: String)
}

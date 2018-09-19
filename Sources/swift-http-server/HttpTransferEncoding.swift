public enum HttpTransferEncoding: String {
    case chunked = "chunked"
    case compress = "compress"
    case deflate = "deflate"
    case gzip = "gzip"
    case identity = "identity"
}

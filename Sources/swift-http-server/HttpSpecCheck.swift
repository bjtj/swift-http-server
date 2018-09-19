

func requiredKeepConnect(specVersion: String, header: HttpHeader) -> Bool {
    return requiredKeepConnect(specVersion: HttpSpecVersion(rawValue: specVersion)!, header: header)
}

func requiredKeepConnect(specVersion: HttpSpecVersion, header: HttpHeader) -> Bool {
    switch specVersion {
    case .HTTP1_0:
        return header.connectionType == .keep_alive
    case .HTTP1_1:
        return header.connectionType == nil || header.connectionType == .keep_alive
    }
}

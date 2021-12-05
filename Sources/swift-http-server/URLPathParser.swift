import Foundation


/**
 URL Path Parser
 */
class URLPathParser {

    enum ParameterType {
        case queryParameter, pathParameter
    }

    let string: String
    public var path: String
    public var pathParameterString: String?
    public var queryString: String?
    public var fragmentString: String?
    var _pathParameters = KeyValuesDict()
    var _queryParameters = KeyValuesDict()

    public var fragment: String? {
        get {
            return fragmentString
        }
        set (value) {
            fragmentString = value
        }
    }

    init(string: String) {
        self.string = string

        var tokens = string.split(separator: "#", maxSplits: 1)
        if tokens.count > 1 {
            fragmentString = String(tokens[1])
        }

        let withoutFragment = tokens[0]
        tokens = withoutFragment.split(separator: "?", maxSplits: 1)

        if tokens.count > 1 {
            queryString = String(tokens[1])
        }

        let pathPart = String(tokens[0])
        
        tokens = pathPart.split(separator: ";", maxSplits: 1)

        if tokens.count > 1 {
            pathParameterString = String(tokens[1])
        }

        path = String(tokens[0])

        if let pathParameterString = pathParameterString {
            let tokens = pathParameterString.split(separator: ";")
            tokens.map { $0.split(separator: "=", maxSplits: 1).map { String($0) } }.forEach {
                _pathParameters.appendValue(forKey: $0[0], value: ($0.count > 1 ? $0[1] : ""))
            }
        }

        if let queryString = queryString {
            let tokens = queryString.split(separator: "&")
            tokens.map { $0.split(separator: "=", maxSplits: 1).map { String($0) } }.forEach {
                _queryParameters.appendValue(forKey: $0[0], value: ($0.count > 1 ? $0[1] : ""))
            }
        }
    }

    var describePathParameter: String {
        let string = _pathParameters.joined(elementsSeparator: ";", separator: "=")
        guard string.isEmpty == false else {
            return ""
        }
        return ";\(string)"
    }

    var describeQuery: String {
        let string = _queryParameters.joined(elementsSeparator: "&", separator: "=")
        guard string.isEmpty == false else {
            return ""
        }
        return "?\(string)"
    }

    var describeFragment: String {
        guard let string = fragmentString, string.isEmpty == false else {
            return ""
        }
        return "#\(string)"
    }

    public var countAllQueryParameters: Int {
        return _queryParameters.countAll
    }

    public var countAllPathParameters: Int {
        return _pathParameters.countAll
    }

    public var description: String {
        return "\(path)\(describePathParameter)\(describeQuery)\(describeFragment)"
    }

    public func keys(of type: ParameterType) -> [String] {
        switch type {
        case .queryParameter:
            return _queryParameters.keys
        case .pathParameter:
            return _pathParameters.keys
        }
    }

    public func parameter(_ key: String, of type: ParameterType = .queryParameter) -> String? {
        switch type {
        case .queryParameter:
            return _queryParameters.value(forKey: key)
        case .pathParameter:
            return _pathParameters.value(forKey: key)
        }
    }

    public func parameters(_ key: String, of type: ParameterType = .queryParameter) -> [String]? {
        switch type {
        case .queryParameter:
            return _queryParameters.values(forKey: key)
        case .pathParameter:
            return _pathParameters.values(forKey: key)
        }
    }

    public func setParameter(_ key: String, _ value: String, of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.setValue(forKey: key, value: value)
        case .pathParameter:
            _pathParameters.setValue(forKey: key, value: value)
        }
    }

    public func setParameters(_ key: String, _ values: [String], of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.setValues(forKey: key, values: values)
        case .pathParameter:
            _pathParameters.setValues(forKey: key, values: values)
        }
    }

    public func appendParameter(_ key: String, value: String, of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.appendValue(forKey: key, value: value)
        case .pathParameter:
            _pathParameters.appendValue(forKey: key, value: value)
        }
    }

    public func appendParameters(_ key: String, values: [String], of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.appendValues(forKey: key, values: values)
        case .pathParameter:
            _pathParameters.appendValues(forKey: key, values: values)
        }
    }

    public func removeParameter(_ key: String, of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.remove(key: key)
        case .pathParameter:
            _pathParameters.remove(key: key)
        }
    }

    public func removeParameter(_ key: String, at: Int, of type: ParameterType = .queryParameter) {
        switch type {
        case .queryParameter:
            _queryParameters.removeValue(forKey: key, at: at)
        case .pathParameter:
            _pathParameters.removeValue(forKey: key, at: at)
        }
    }
}


class KeyValuePair {
    public var key: String?
    public var value: String?

    public init(key: String?, value: String?) {
        self.key = key
        self.value = value
    }
}

public class FirstLine {
    private var parts = ["", "", ""]
    public var first: String {
        get {return parts[0]}
        set(value) { parts[0] = value }
    }
    public var second: String {
        get {return parts[1]}
        set(value) { parts[1] = value }
    }
    public var third: String {
        get {return parts[2]}
        set(value) { parts[2] = value }
    }

    public var description: String {
        return parts.joined(separator: " ")
    }

    public static func read(text: String) -> FirstLine {
        let firstLine = FirstLine()
        let tokens = text.split(separator: " ", maxSplits: 2)
        firstLine.first = String(tokens[0])
        firstLine.second = String(tokens[1])
        firstLine.third = String(tokens[2])
        return firstLine
    }
}

public class HttpHeader {

    public var specVersion: HttpSpecVersion?
    public var firstLine = FirstLine()
    var fields: [KeyValuePair] = []

    public func contains(key: String?) -> Bool {
        for field in fields {
            if field.key?.caseInsensitiveCompare(key!) == .orderedSame {
                return true
            }
        }
        return false
    }

    public var contentLength: Int? {
        get {
            guard let length = self["Content-Length"] else {
                return nil
            }
            return Int(length)
        }
        set(value) {
            self["Content-Length"] = "\(value!)"
        }
    }

    public var contentType: String? {
        get {
            guard let type = self["Content-Type"] else {
                return nil
            }
            return type
        }
        set(value) {
            self["Content-Type"] = value
        }
    }

    public var connectionType: HttpConnectionType? {
        get {
            guard let connection = self["Connection"] else {
                return nil
            }
            if connection.caseInsensitiveCompare("close") == .orderedSame {
                return .close
            }
            if connection.caseInsensitiveCompare("keep-alive") == .orderedSame {
                return .keep_alive
            }
            return nil
        }
        set(value) {
            guard let type = value else {
                self["Connection"] = nil
                return
            }
            self["Connection"] = type.rawValue
        }
    }

    public var transferEncoding: HttpTransferEncoding? {
        get {
            guard let encoding = self["Transfer-Encoding"] else {
                return nil
            }
            if encoding.caseInsensitiveCompare("chunked") == .orderedSame {
                return .chunked
            }
            return nil
        }
        set (value) {
            guard let encoding = value else {
                self["Transfer-Encoding"] = nil
                return
            }
            self["Transfer-Encoding"] = encoding.rawValue
        }
    }

    public var expect: String? {
        get {
            return self["Expect"]
        }
        set(value) {
            self["Expect"] = value
        }
    }

    public var isExpect100: Bool {
        guard let expect = self["Expect"] else {
            return false
        }
        return expect.hasPrefix("100-")
    }

    subscript (key: String) -> String? {
        get {
            for field in fields {
                if field.key?.caseInsensitiveCompare(key) == .orderedSame {
                    return field.value
                }
            }
            return nil
        }
        set (value) {
            for field in fields {
                if field.key?.caseInsensitiveCompare(key) == .orderedSame {
                    field.value = value
                }
            }
            fields.append(KeyValuePair(key: key, value: value))
        }
    }

    public var description: String {
        let fieldsString = fields.map { "\($0.key!): \($0.value!)" }.joined(separator: "\r\n")
        return "\(firstLine.description)\r\n\(fieldsString)\r\n\r\n"
    }

    public static func read(text: String) -> HttpHeader {
        let header = HttpHeader()
        let lines = text.components(separatedBy: "\r\n")
        var first = true
        for line in lines {
            if line.isEmpty {
                break
            }
            if first {
                header.firstLine = FirstLine.read(text: line)
                first = false
            } else {
                let tokens = line.split(separator: ":", maxSplits: 1)
                header[tokens[0].trimmingCharacters(in: .whitespaces)] =
                  (tokens.count == 1 ? "" : "\(tokens[1])").trimmingCharacters(in: .whitespaces)
            }
        }
        return header
    }
}
